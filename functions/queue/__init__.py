import json, os, psycopg, logging
import azure.functions as func
from azure.messaging.webpubsubservice import WebPubSubServiceClient
from shared.db import get_pool

logging.basicConfig(level=logging.INFO)

# ----------------- config -----------------
POOL              = get_pool()
WPS_CLIENT        = WebPubSubServiceClient.from_connection_string(
    os.environ["EVENTS_CONNECTION"], hub="fleet"
)
# ------------------------------------------


def _handle_cimian_run(row: dict, cur):
    payload = row["payload"]
    cur.execute(
        """
        insert into cimian(id, device_id, ts, exit_code, duration, details)
        values (%s,%s,%s,%s,%s,%s)
        on conflict do nothing
        """,
        (
            row["id"],
            row["device"],
            row["ts"],
            payload.get("exitCode"),
            payload.get("duration"),
            payload.get("details"),
        ),
    )


def _handle_munki_run(row: dict, cur):
    payload = row["payload"]
    cur.execute(
        """
        insert into munki(id, device_id, ts, exit_code, duration, details)
        values (%s,%s,%s,%s,%s,%s)
        on conflict do nothing
        """,
        (
            row["id"],
            row["device"],
            row["ts"],
            payload.get("exitCode"),
            payload.get("duration"),
            payload.get("details"),
        ),
    )


def _ensure_device_exists(device_id: str, row: dict, cur):
    """
    Ensure device exists in database and assign to machine group if passphrase provided.
    Also handle device data from new_client events.
    """
    machine_group_id = None
    passphrase_hash = row.get("passphrase_hash")
    
    # If passphrase hash is provided, find matching machine group
    if passphrase_hash:
        cur.execute(
            "SELECT id FROM machine_groups WHERE passphrase_hash = %s LIMIT 1",
            (passphrase_hash,)
        )
        result = cur.fetchone()
        if result:
            machine_group_id = result[0]
            logging.info(f"Device {device_id} assigned to machine group {machine_group_id}")
        else:
            logging.warning(f"No machine group found for passphrase hash: {passphrase_hash[:8]}...")
    
    # Extract device info from payload if it's a new_client event
    name = device_id
    model = "Unknown"
    os = "Unknown"
    manufacturer = "Unknown"
    
    if row.get("kind") == "new_client":
        payload = row.get("payload", {})
        name = payload.get("name", device_id)
        model = payload.get("model", "Unknown")
        os = payload.get("os", "Unknown")
        manufacturer = payload.get("manufacturer", "Unknown")
        logging.info(f"New client registration: {device_id} ({name})")
    
    # For device_data events, extract device info from the nested device object
    elif row.get("kind") == "device_data":
        payload = row.get("payload", {})
        device_info = payload.get("device", {})
        if isinstance(device_info, dict):
            name = device_info.get("ComputerName", device_info.get("name", device_id))
            model = device_info.get("Model", device_info.get("model", "Unknown"))
            os = device_info.get("OperatingSystem", device_info.get("os", "Unknown"))
            manufacturer = device_info.get("Manufacturer", device_info.get("manufacturer", "Unknown"))
    
    # Upsert device with comprehensive info
    cur.execute(
        """
        INSERT INTO devices (id, name, model, os, manufacturer, machine_group_id, last_seen, status, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, NOW(), 'active', NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            model = EXCLUDED.model,
            os = EXCLUDED.os,
            manufacturer = EXCLUDED.manufacturer,
            machine_group_id = COALESCE(EXCLUDED.machine_group_id, devices.machine_group_id),
            last_seen = NOW(),
            status = 'active',
            updated_at = NOW()
        """,
        (device_id, name, model, os, manufacturer, machine_group_id)
    )


def main(msg: func.QueueMessage):
    raw: str = msg.get_body().decode()
    row = json.loads(raw)

    with POOL.connection() as conn:
        cur = conn.cursor()
        
        # Ensure device exists and assign to machine group if applicable
        _ensure_device_exists(row["device"], row, cur)
        
        if row["kind"] == "cimian_run":
            _handle_cimian_run(row, cur)
        elif row["kind"] == "munki_run":
            _handle_munki_run(row, cur)
        else:
            # generic fallback into events table
            cur.execute(
                """
                insert into events(id, device_id, kind, ts, payload)
                values (%s,%s,%s,%s,%s::jsonb)
                on conflict do nothing
                """,
                (
                    row["id"],
                    row["device"],
                    row["kind"],
                    row["ts"],
                    json.dumps(row["payload"]),
                ),
            )

    # broadcast to dashboards
    WPS_CLIENT.send_to_all(json.dumps([row]), content_type="application/json")