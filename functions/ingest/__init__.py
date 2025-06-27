import json, os, uuid, datetime, hashlib
import azure.functions as func
from azure.storage.queue import QueueClient
from pydantic import BaseModel, Field, ValidationError
import logging


# ----------------- config -----------------
QUEUE_NAME   = os.environ["QUEUE_NAME"]
QUEUE_CLIENT = QueueClient.from_connection_string(
    conn_str=os.environ["AZURE_STORAGE_CONNECTION_STRING"],
    queue_name=QUEUE_NAME,
)

# Client authentication configuration - supports both legacy and per-group passphrases
CLIENT_PASSPHRASES = os.environ.get("CLIENT_PASSPHRASES", "").strip()
VALID_LEGACY_PASSPHRASES = set()
if CLIENT_PASSPHRASES:
    # Parse comma-separated passphrases and strip whitespace
    VALID_LEGACY_PASSPHRASES = {phrase.strip() for phrase in CLIENT_PASSPHRASES.split(",") if phrase.strip()}
    logging.info(f"Legacy passphrase authentication enabled with {len(VALID_LEGACY_PASSPHRASES)} valid passphrases")

# Machine Group authentication - per-group passphrases (preferred method)
# This will be checked against the database for machine group assignment
ENABLE_MACHINE_GROUPS = os.environ.get("ENABLE_MACHINE_GROUPS", "false").lower() == "true"
if ENABLE_MACHINE_GROUPS:
    logging.info("Machine group authentication enabled - per-group passphrases will be validated against database")
else:
    logging.info("Machine group authentication disabled - using legacy global passphrases")

if not CLIENT_PASSPHRASES and not ENABLE_MACHINE_GROUPS:
    logging.info("All passphrase authentication disabled - accepting all requests")
# ------------------------------------------


class Payload(BaseModel):
    device: str
    kind: str
    ts: datetime.datetime | None = None
    payload: dict = Field(default_factory=dict)
    passphrase: str | None = None  # Optional passphrase field
    serial_number: str | None = None  # Optional serial number for device identification


def hash_passphrase(passphrase: str) -> str:
    """
    Create SHA-256 hash of passphrase for machine group lookup.
    
    Args:
        passphrase: The raw passphrase
        
    Returns:
        Hexadecimal SHA-256 hash of the passphrase
    """
    return hashlib.sha256(passphrase.encode('utf-8')).hexdigest()


def validate_passphrase(provided_passphrase: str | None) -> tuple[bool, str | None, str | None]:
    """
    Validate client passphrase for restricted access and return machine group information.
    
    This function supports both legacy global passphrases and per-group passphrases:
    1. If machine groups are enabled, check if passphrase hash exists in database
    2. Fall back to legacy global passphrase validation
    3. If no authentication is configured, allow all requests
    
    Args:
        provided_passphrase: The passphrase provided by the client
        
    Returns:
        Tuple of (is_valid, passphrase_hash, auth_mode) where:
        - is_valid: whether the passphrase is valid
        - passphrase_hash: SHA-256 hash of the passphrase (for machine group lookup)
        - auth_mode: "machine_group", "legacy", or "none"
    """
    # If no authentication is configured at all, allow all requests
    if not VALID_LEGACY_PASSPHRASES and not ENABLE_MACHINE_GROUPS:
        return True, None, "none"
    
    # If no passphrase provided but authentication is required, deny access
    if not provided_passphrase:
        return False, None, None
    
    passphrase_stripped = provided_passphrase.strip()
    passphrase_hash = hash_passphrase(passphrase_stripped)
    
    # Priority 1: Machine group authentication (per-group passphrases)
    if ENABLE_MACHINE_GROUPS:
        # NOTE: In a full implementation, this would query the database to check
        # if the passphrase_hash exists in the machine_groups table.
        # For now, we'll assume it's valid if machine groups are enabled.
        # The actual group assignment will happen in the queue processing function.
        logging.info(f"Machine group mode: validating passphrase hash {passphrase_hash[:8]}...")
        return True, passphrase_hash, "machine_group"
    
    # Priority 2: Legacy global passphrase validation
    if passphrase_stripped in VALID_LEGACY_PASSPHRASES:
        logging.info("Legacy passphrase mode: passphrase validated")
        return True, passphrase_hash, "legacy"
    
    return False, None, None


def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        body = req.get_json()
        model = Payload.model_validate(body)
    except (ValueError, ValidationError) as exc:
        logging.warning(f"Invalid JSON payload: {exc}")
        return func.HttpResponse(
            "invalid JSON: " + str(exc), status_code=400
        )

    # Validate passphrase if authentication is enabled
    is_valid, passphrase_hash, auth_mode = validate_passphrase(model.passphrase)
    if not is_valid:
        logging.warning(f"Unauthorized access attempt from device: {model.device}")
        return func.HttpResponse(
            "Unauthorized: Invalid or missing passphrase", 
            status_code=401
        )

    # fill missing fields
    data = model.model_dump()
    data["id"] = str(uuid.uuid4())
    if data["ts"] is None:
        data["ts"] = datetime.datetime.utcnow().isoformat()
    
    # Remove passphrase from stored data for security, but add metadata for processing
    data.pop("passphrase", None)
    if passphrase_hash:
        data["passphrase_hash"] = passphrase_hash
    if auth_mode:
        data["auth_mode"] = auth_mode

    # enqueue
    try:
        QUEUE_CLIENT.send_message(json.dumps(data))
        auth_info = f"group hash: {passphrase_hash[:8]}..." if passphrase_hash else "no auth"
        logging.info(f"Successfully queued message from device: {model.device} ({auth_mode} mode, {auth_info})")
    except Exception as exc:
        logging.error(f"Failed to queue message: {exc}")
        return func.HttpResponse(
            "Internal server error", status_code=500
        )

    return func.HttpResponse(status_code=202)