import json, os, secrets
import azure.functions as func
import logging
from pydantic import BaseModel, Field, ValidationError
from typing import Optional, List, Dict, Any


class BusinessUnitRequest(BaseModel):
    """Request model for business unit operations"""
    action: str  # create, update, delete, list, get
    unit_id: Optional[int] = None
    name: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    link: Optional[str] = None
    users: Optional[List[str]] = None  # List of usernames
    managers: Optional[List[str]] = None  # List of manager usernames
    archivers: Optional[List[str]] = None  # List of archiver usernames
    groups: Optional[List[str]] = None  # List of group names (prefixed with @)
    machine_groups: Optional[List[int]] = None  # List of machine group IDs


class BusinessUnitResponse(BaseModel):
    """Response model for business unit operations"""
    success: bool
    message: str
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


def create_business_unit(name: str, description: str = None, address: str = None,
                        link: str = None) -> Dict[str, Any]:
    """
    Create a new business unit.
    
    Args:
        name: Name of the business unit
        description: Optional description
        address: Optional address
        link: Optional URL for more information
        
    Returns:
        Dictionary with business unit details
    """
    # TODO: Insert into database
    # INSERT INTO business_units (name, description, address, link, created_at, updated_at)
    # VALUES (?, ?, ?, ?, NOW(), NOW())
    
    # For now, simulate with a dummy unit ID
    unit_id = secrets.randbelow(1000) + 100  # Generate a random ID for demo
    
    logging.info(f"Created business unit '{name}' with ID {unit_id}")
    
    return {
        "unit_id": unit_id,
        "name": name,
        "description": description,
        "address": address,
        "link": link,
        "created_at": func.utcnow().isoformat()
    }


def get_business_units() -> List[Dict[str, Any]]:
    """
    Get all business units with their associated data.
    
    Returns:
        List of business unit dictionaries with full details
    """
    # TODO: Query database with joins
    # SELECT bu.*, 
    #        GROUP_CONCAT(CASE WHEN buu.role = 'user' THEN buu.username END) as users,
    #        GROUP_CONCAT(CASE WHEN buu.role = 'manager' THEN buu.username END) as managers,
    #        GROUP_CONCAT(CASE WHEN buu.role = 'archiver' THEN buu.username END) as archivers,
    #        GROUP_CONCAT(CASE WHEN bug.role = 'user' THEN bug.group_name END) as user_groups,
    #        GROUP_CONCAT(mg.id) as machine_group_ids
    # FROM business_units bu
    # LEFT JOIN business_unit_users buu ON bu.id = buu.business_unit_id
    # LEFT JOIN business_unit_groups bug ON bu.id = bug.business_unit_id
    # LEFT JOIN machine_groups mg ON bu.id = mg.business_unit_id
    # GROUP BY bu.id
    
    # For now, return empty list
    logging.info("Fetching all business units")
    return []


def update_business_unit_memberships(unit_id: int, users: List[str] = None,
                                   managers: List[str] = None, archivers: List[str] = None,
                                   groups: List[str] = None, machine_groups: List[int] = None) -> bool:
    """
    Update business unit user/group memberships and machine group assignments.
    
    This follows MunkiReport's pattern of storing user roles and group assignments
    in separate tables with role-based access control.
    
    Args:
        unit_id: ID of the business unit
        users: List of usernames with 'user' role
        managers: List of usernames with 'manager' role
        archivers: List of usernames with 'archiver' role
        groups: List of group names (prefixed with @) with appropriate roles
        machine_groups: List of machine group IDs to assign to this business unit
        
    Returns:
        True if successful, False otherwise
    """
    # TODO: Database transaction
    # 1. DELETE FROM business_unit_users WHERE business_unit_id = ?
    # 2. DELETE FROM business_unit_groups WHERE business_unit_id = ?
    # 3. UPDATE machine_groups SET business_unit_id = NULL WHERE business_unit_id = ?
    # 4. INSERT new user assignments
    # 5. INSERT new group assignments
    # 6. UPDATE machine group assignments
    
    updates = []
    
    # Process user assignments
    if users:
        for username in users:
            # INSERT INTO business_unit_users (business_unit_id, username, role)
            # VALUES (?, ?, 'user')
            updates.append(f"User '{username}' -> user role")
    
    if managers:
        for username in managers:
            updates.append(f"User '{username}' -> manager role")
    
    if archivers:
        for username in archivers:
            updates.append(f"User '{username}' -> archiver role")
    
    # Process group assignments (names should be prefixed with @)
    if groups:
        for group_name in groups:
            if not group_name.startswith('@'):
                group_name = '@' + group_name
            updates.append(f"Group '{group_name}' assigned")
    
    # Process machine group assignments
    if machine_groups:
        for mg_id in machine_groups:
            # UPDATE machine_groups SET business_unit_id = ? WHERE id = ?
            updates.append(f"Machine group {mg_id} assigned")
    
    if updates:
        logging.info(f"Updated business unit {unit_id} memberships: {updates}")
        return True
    
    return False


def update_business_unit(unit_id: int, name: str = None, description: str = None,
                        address: str = None, link: str = None) -> bool:
    """
    Update basic business unit information.
    
    Args:
        unit_id: ID of the business unit to update
        name: New name (optional)
        description: New description (optional)
        address: New address (optional)
        link: New link (optional)
        
    Returns:
        True if successful, False otherwise
    """
    # TODO: Update database
    updates = {}
    if name:
        updates["name"] = name
    if description is not None:  # Allow empty string
        updates["description"] = description
    if address is not None:
        updates["address"] = address
    if link is not None:
        updates["link"] = link
    
    if updates:
        updates["updated_at"] = func.utcnow().isoformat()
        logging.info(f"Updated business unit {unit_id} with: {list(updates.keys())}")
        return True
    
    return False


def delete_business_unit(unit_id: int) -> bool:
    """
    Delete a business unit and unassign its machine groups.
    
    Args:
        unit_id: ID of the business unit to delete
        
    Returns:
        True if successful, False otherwise
    """
    # TODO: Database transaction
    # 1. UPDATE machine_groups SET business_unit_id = NULL WHERE business_unit_id = ?
    # 2. DELETE FROM business_unit_groups WHERE business_unit_id = ?
    # 3. DELETE FROM business_unit_users WHERE business_unit_id = ?
    # 4. DELETE FROM business_units WHERE id = ?
    
    logging.info(f"Deleted business unit {unit_id} and unassigned machine groups")
    return True


def get_max_unit_id() -> int:
    """
    Get the maximum business unit ID for creating new units.
    
    Returns:
        Maximum unit ID + 1, or 1 if no units exist
    """
    # TODO: Query database
    # SELECT MAX(id) FROM business_units
    
    # For now, return a dummy value
    return secrets.randbelow(1000) + 100


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Azure Function for managing business units.
    
    Supports operations: create, update, delete, list, get
    Based on MunkiReport's business unit management patterns.
    """
    try:
        # Parse request
        body = req.get_json()
        request_data = BusinessUnitRequest.model_validate(body)
    except (ValueError, ValidationError) as exc:
        logging.warning(f"Invalid request payload: {exc}")
        response = BusinessUnitResponse(
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
                raise ValueError("Name is required for creating business units")
            
            # Create the business unit
            unit_data = create_business_unit(
                name=request_data.name,
                description=request_data.description,
                address=request_data.address,
                link=request_data.link
            )
            
            # Update memberships if provided
            if any([request_data.users, request_data.managers, request_data.archivers,
                   request_data.groups, request_data.machine_groups]):
                update_business_unit_memberships(
                    unit_id=unit_data["unit_id"],
                    users=request_data.users,
                    managers=request_data.managers,
                    archivers=request_data.archivers,
                    groups=request_data.groups,
                    machine_groups=request_data.machine_groups
                )
            
            response = BusinessUnitResponse(
                success=True,
                message=f"Business unit '{request_data.name}' created successfully",
                data=unit_data
            )
            
        elif request_data.action == "list":
            units = get_business_units()
            response = BusinessUnitResponse(
                success=True,
                message="Business units retrieved successfully",
                data={"units": units}
            )
            
        elif request_data.action == "update":
            if not request_data.unit_id:
                raise ValueError("Unit ID is required for updating business units")
            
            # Update basic info
            basic_success = update_business_unit(
                unit_id=request_data.unit_id,
                name=request_data.name,
                description=request_data.description,
                address=request_data.address,
                link=request_data.link
            )
            
            # Update memberships
            membership_success = True
            if any([request_data.users, request_data.managers, request_data.archivers,
                   request_data.groups, request_data.machine_groups]):
                membership_success = update_business_unit_memberships(
                    unit_id=request_data.unit_id,
                    users=request_data.users,
                    managers=request_data.managers,
                    archivers=request_data.archivers,
                    groups=request_data.groups,
                    machine_groups=request_data.machine_groups
                )
            
            if basic_success or membership_success:
                response = BusinessUnitResponse(
                    success=True,
                    message=f"Business unit {request_data.unit_id} updated successfully"
                )
            else:
                response = BusinessUnitResponse(
                    success=False,
                    message=f"Failed to update business unit {request_data.unit_id}",
                    error="No changes made"
                )
                
        elif request_data.action == "delete":
            if not request_data.unit_id:
                raise ValueError("Unit ID is required for deleting business units")
            
            success = delete_business_unit(request_data.unit_id)
            
            if success:
                response = BusinessUnitResponse(
                    success=True,
                    message=f"Business unit {request_data.unit_id} deleted successfully"
                )
            else:
                response = BusinessUnitResponse(
                    success=False,
                    message=f"Failed to delete business unit {request_data.unit_id}",
                    error="Unit not found or deletion failed"
                )
                
        else:
            response = BusinessUnitResponse(
                success=False,
                message=f"Unknown action: {request_data.action}",
                error="Supported actions: create, update, delete, list"
            )
            
    except Exception as exc:
        logging.error(f"Error processing business unit request: {exc}")
        response = BusinessUnitResponse(
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
