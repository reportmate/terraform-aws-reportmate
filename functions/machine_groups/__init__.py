import json, os, uuid, hashlib, secrets
import azure.functions as func
import logging
from pydantic import BaseModel, Field, ValidationError
from typing import Optional, List, Dict, Any


class MachineGroupRequest(BaseModel):
    """Request model for machine group operations"""
    action: str  # create, update, delete, list, get
    group_id: Optional[int] = None
    name: Optional[str] = None
    description: Optional[str] = None
    business_unit_id: Optional[int] = None
    generate_passphrase: bool = False
    passphrase: Optional[str] = None  # Raw passphrase (will be hashed)


class MachineGroupResponse(BaseModel):
    """Response model for machine group operations"""
    success: bool
    message: str
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


def generate_guid_passphrase() -> str:
    """
    Generate a GUID-style passphrase similar to MunkiReport.
    
    Returns:
        A UUID-style string that can be used as a machine group passphrase
    """
    # Generate a UUID4 and format it in uppercase like MunkiReport
    guid = str(uuid.uuid4()).upper()
    return guid


def hash_passphrase(passphrase: str) -> str:
    """
    Create SHA-256 hash of passphrase for storage.
    
    Args:
        passphrase: The raw passphrase
        
    Returns:
        Hexadecimal SHA-256 hash of the passphrase
    """
    return hashlib.sha256(passphrase.encode('utf-8')).hexdigest()


def passphrase_to_group_id(passphrase_hash: str) -> Optional[int]:
    """
    Lookup machine group ID by passphrase hash.
    
    In a full implementation, this would query the database:
    SELECT id FROM machine_groups WHERE passphrase_hash = ?
    
    Args:
        passphrase_hash: SHA-256 hash of the passphrase
        
    Returns:
        Machine group ID if found, None otherwise
    """
    # TODO: Implement database lookup
    # This is a placeholder for database integration
    logging.info(f"Looking up group for passphrase hash: {passphrase_hash[:8]}...")
    return None


def create_machine_group(name: str, passphrase: str = None, description: str = None, 
                        business_unit_id: int = None) -> Dict[str, Any]:
    """
    Create a new machine group with unique passphrase.
    
    Args:
        name: Name of the machine group
        passphrase: Optional custom passphrase (will generate one if not provided)
        description: Optional description
        business_unit_id: Optional business unit assignment
        
    Returns:
        Dictionary with group details including generated passphrase
    """
    # Generate passphrase if not provided
    if not passphrase:
        passphrase = generate_guid_passphrase()
    
    passphrase_hash = hash_passphrase(passphrase)
    
    # TODO: Insert into database
    # INSERT INTO machine_groups (name, description, passphrase_hash, business_unit_id, created_at, updated_at)
    # VALUES (?, ?, ?, ?, NOW(), NOW())
    
    # For now, simulate with a dummy group ID
    group_id = secrets.randbelow(10000) + 1000  # Generate a random ID for demo
    
    logging.info(f"Created machine group '{name}' with ID {group_id}")
    
    return {
        "group_id": group_id,
        "name": name,
        "description": description,
        "passphrase": passphrase,  # Return the raw passphrase for client configuration
        "passphrase_hash": passphrase_hash,
        "business_unit_id": business_unit_id,
        "created_at": func.utcnow().isoformat()
    }


def get_machine_groups(business_unit_id: int = None) -> List[Dict[str, Any]]:
    """
    Get all machine groups, optionally filtered by business unit.
    
    Args:
        business_unit_id: Optional business unit filter
        
    Returns:
        List of machine group dictionaries (without raw passphrases)
    """
    # TODO: Query database
    # SELECT id, name, description, business_unit_id, created_at, updated_at
    # FROM machine_groups
    # WHERE business_unit_id = ? OR ? IS NULL
    
    # For now, return empty list
    logging.info(f"Fetching machine groups for business unit: {business_unit_id}")
    return []


def update_machine_group(group_id: int, name: str = None, description: str = None,
                        business_unit_id: int = None, new_passphrase: str = None) -> bool:
    """
    Update an existing machine group.
    
    Args:
        group_id: ID of the group to update
        name: New name (optional)
        description: New description (optional)
        business_unit_id: New business unit assignment (optional)
        new_passphrase: New passphrase (optional, will regenerate hash)
        
    Returns:
        True if successful, False otherwise
    """
    # TODO: Update database
    updates = {}
    if name:
        updates["name"] = name
    if description:
        updates["description"] = description
    if business_unit_id is not None:
        updates["business_unit_id"] = business_unit_id
    if new_passphrase:
        updates["passphrase_hash"] = hash_passphrase(new_passphrase)
    
    if updates:
        updates["updated_at"] = func.utcnow().isoformat()
        logging.info(f"Updated machine group {group_id} with: {list(updates.keys())}")
        return True
    
    return False


def delete_machine_group(group_id: int) -> bool:
    """
    Delete a machine group and reassign its devices to group 0 (unassigned).
    
    Args:
        group_id: ID of the group to delete
        
    Returns:
        True if successful, False otherwise
    """
    # TODO: Database transaction
    # 1. UPDATE devices SET machine_group_id = NULL WHERE machine_group_id = ?
    # 2. DELETE FROM machine_groups WHERE id = ?
    
    logging.info(f"Deleted machine group {group_id} and reassigned devices to unassigned")
    return True


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Azure Function for managing machine groups.
    
    Supports operations: create, update, delete, list, get
    Based on MunkiReport's machine group management patterns.
    """
    try:
        # Parse request
        body = req.get_json()
        request_data = MachineGroupRequest.model_validate(body)
    except (ValueError, ValidationError) as exc:
        logging.warning(f"Invalid request payload: {exc}")
        response = MachineGroupResponse(
            success=False,
            message="Invalid request format",
            error=str(exc)
        )
        return func.HttpResponse(
            response.model_dump_json(),
            status_code=400,
            mimetype="application/json"
        )

    try:
        # Route based on action
        if request_data.action == "create":
            if not request_data.name:
                raise ValueError("Name is required for creating machine groups")
            
            passphrase = None
            if request_data.generate_passphrase:
                passphrase = generate_guid_passphrase()
            elif request_data.passphrase:
                passphrase = request_data.passphrase
            
            group_data = create_machine_group(
                name=request_data.name,
                passphrase=passphrase,
                description=request_data.description,
                business_unit_id=request_data.business_unit_id
            )
            
            response = MachineGroupResponse(
                success=True,
                message=f"Machine group '{request_data.name}' created successfully",
                data=group_data
            )
            
        elif request_data.action == "list":
            groups = get_machine_groups(request_data.business_unit_id)
            response = MachineGroupResponse(
                success=True,
                message="Machine groups retrieved successfully",
                data={"groups": groups}
            )
            
        elif request_data.action == "update":
            if not request_data.group_id:
                raise ValueError("Group ID is required for updating machine groups")
            
            success = update_machine_group(
                group_id=request_data.group_id,
                name=request_data.name,
                description=request_data.description,
                business_unit_id=request_data.business_unit_id,
                new_passphrase=request_data.passphrase
            )
            
            if success:
                response = MachineGroupResponse(
                    success=True,
                    message=f"Machine group {request_data.group_id} updated successfully"
                )
            else:
                response = MachineGroupResponse(
                    success=False,
                    message=f"Failed to update machine group {request_data.group_id}",
                    error="No changes made"
                )
                
        elif request_data.action == "delete":
            if not request_data.group_id:
                raise ValueError("Group ID is required for deleting machine groups")
            
            success = delete_machine_group(request_data.group_id)
            
            if success:
                response = MachineGroupResponse(
                    success=True,
                    message=f"Machine group {request_data.group_id} deleted successfully"
                )
            else:
                response = MachineGroupResponse(
                    success=False,
                    message=f"Failed to delete machine group {request_data.group_id}",
                    error="Group not found or deletion failed"
                )
                
        else:
            response = MachineGroupResponse(
                success=False,
                message=f"Unknown action: {request_data.action}",
                error="Supported actions: create, update, delete, list"
            )
            
    except Exception as exc:
        logging.error(f"Error processing machine group request: {exc}")
        response = MachineGroupResponse(
            success=False,
            message="Internal server error",
            error=str(exc)
        )
        return func.HttpResponse(
            response.model_dump_json(),
            status_code=500,
            mimetype="application/json"
        )

    return func.HttpResponse(
        response.model_dump_json(),
        mimetype="application/json"
    )
