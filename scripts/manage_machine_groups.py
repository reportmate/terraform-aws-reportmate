#!/usr/bin/env python3
"""
ReportMate Machine Group Management Script

This script provides command-line utilities for managing machine groups,
inspired by MunkiReport's machine group management patterns.

Usage:
    python manage_machine_groups.py create --name "Sales Team" --generate-passphrase
    python manage_machine_groups.py create --name "IT Department" --passphrase "custom-key-123"
    python manage_machine_groups.py list
    python manage_machine_groups.py update --group-id 1 --name "Sales Department"
    python manage_machine_groups.py delete --group-id 1
"""

import argparse
import json
import sys
import requests
import uuid
import hashlib
from typing import Optional, Dict, Any


class MachineGroupManager:
    """Manager for ReportMate machine groups"""
    
    def __init__(self, api_base_url: str, api_key: str = None):
        """
        Initialize the machine group manager.
        
        Args:
            api_base_url: Base URL for the ReportMate API
            api_key: Optional API key for authentication
        """
        self.api_base_url = api_base_url.rstrip('/')
        self.api_key = api_key
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({'X-API-Key': api_key})
    
    def generate_guid_passphrase(self) -> str:
        """Generate a GUID-style passphrase like MunkiReport"""
        return str(uuid.uuid4()).upper()
    
    def hash_passphrase(self, passphrase: str) -> str:
        """Create SHA-256 hash of passphrase"""
        return hashlib.sha256(passphrase.encode('utf-8')).hexdigest()
    
    def create_machine_group(self, name: str, description: str = None, 
                           business_unit_id: int = None, passphrase: str = None,
                           generate_passphrase: bool = False) -> Dict[str, Any]:
        """
        Create a new machine group.
        
        Args:
            name: Name of the machine group
            description: Optional description
            business_unit_id: Optional business unit assignment
            passphrase: Custom passphrase (if not provided and generate_passphrase is False, server generates one)
            generate_passphrase: Whether to generate a GUID-style passphrase
            
        Returns:
            Dictionary with API response
        """
        payload = {
            "action": "create",
            "name": name,
            "description": description,
            "business_unit_id": business_unit_id,
            "generate_passphrase": generate_passphrase,
            "passphrase": passphrase
        }
        
        # Remove None values
        payload = {k: v for k, v in payload.items() if v is not None}
        
        response = self.session.post(
            f"{self.api_base_url}/api/machine_groups",
            json=payload
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"API request failed: {response.status_code} - {response.text}")
    
    def list_machine_groups(self, business_unit_id: int = None) -> Dict[str, Any]:
        """
        List all machine groups.
        
        Args:
            business_unit_id: Optional filter by business unit
            
        Returns:
            Dictionary with API response
        """
        payload = {
            "action": "list",
            "business_unit_id": business_unit_id
        }
        
        # Remove None values
        payload = {k: v for k, v in payload.items() if v is not None}
        
        response = self.session.post(
            f"{self.api_base_url}/api/machine_groups",
            json=payload
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"API request failed: {response.status_code} - {response.text}")
    
    def update_machine_group(self, group_id: int, name: str = None, 
                           description: str = None, business_unit_id: int = None,
                           passphrase: str = None) -> Dict[str, Any]:
        """
        Update an existing machine group.
        
        Args:
            group_id: ID of the group to update
            name: New name
            description: New description
            business_unit_id: New business unit assignment
            passphrase: New passphrase
            
        Returns:
            Dictionary with API response
        """
        payload = {
            "action": "update",
            "group_id": group_id,
            "name": name,
            "description": description,
            "business_unit_id": business_unit_id,
            "passphrase": passphrase
        }
        
        # Remove None values
        payload = {k: v for k, v in payload.items() if v is not None}
        
        response = self.session.post(
            f"{self.api_base_url}/api/machine_groups",
            json=payload
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"API request failed: {response.status_code} - {response.text}")
    
    def delete_machine_group(self, group_id: int) -> Dict[str, Any]:
        """
        Delete a machine group.
        
        Args:
            group_id: ID of the group to delete
            
        Returns:
            Dictionary with API response
        """
        payload = {
            "action": "delete",
            "group_id": group_id
        }
        
        response = self.session.post(
            f"{self.api_base_url}/api/machine_groups",
            json=payload
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"API request failed: {response.status_code} - {response.text}")


def main():
    """Main CLI interface"""
    parser = argparse.ArgumentParser(description="ReportMate Machine Group Management")
    parser.add_argument("--api-url", default="https://your-reportmate.azurewebsites.net", 
                       help="Base URL for ReportMate API")
    parser.add_argument("--api-key", help="API key for authentication")
    
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Create command
    create_parser = subparsers.add_parser("create", help="Create a new machine group")
    create_parser.add_argument("--name", required=True, help="Name of the machine group")
    create_parser.add_argument("--description", help="Description of the machine group")
    create_parser.add_argument("--business-unit-id", type=int, help="Business unit ID to assign to")
    create_parser.add_argument("--passphrase", help="Custom passphrase for the group")
    create_parser.add_argument("--generate-passphrase", action="store_true", 
                              help="Generate a GUID-style passphrase")
    
    # List command
    list_parser = subparsers.add_parser("list", help="List machine groups")
    list_parser.add_argument("--business-unit-id", type=int, help="Filter by business unit ID")
    
    # Update command
    update_parser = subparsers.add_parser("update", help="Update a machine group")
    update_parser.add_argument("--group-id", type=int, required=True, help="ID of the group to update")
    update_parser.add_argument("--name", help="New name for the group")
    update_parser.add_argument("--description", help="New description for the group")
    update_parser.add_argument("--business-unit-id", type=int, help="New business unit ID")
    update_parser.add_argument("--passphrase", help="New passphrase for the group")
    
    # Delete command
    delete_parser = subparsers.add_parser("delete", help="Delete a machine group")
    delete_parser.add_argument("--group-id", type=int, required=True, help="ID of the group to delete")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        manager = MachineGroupManager(args.api_url, args.api_key)
        
        if args.command == "create":
            result = manager.create_machine_group(
                name=args.name,
                description=args.description,
                business_unit_id=args.business_unit_id,
                passphrase=args.passphrase,
                generate_passphrase=args.generate_passphrase
            )
            
            if result.get("success"):
                print(f"✅ Machine group created successfully!")
                print(f"📋 Group ID: {result['data']['group_id']}")
                print(f"📝 Name: {result['data']['name']}")
                if result['data'].get('passphrase'):
                    print(f"🔑 Passphrase: {result['data']['passphrase']}")
                    print(f"💡 Use this passphrase on clients:")
                    print(f"   defaults write /Library/Preferences/ReportMate Passphrase '{result['data']['passphrase']}'")
            else:
                print(f"❌ Failed to create machine group: {result.get('message', 'Unknown error')}")
                sys.exit(1)
        
        elif args.command == "list":
            result = manager.list_machine_groups(args.business_unit_id)
            
            if result.get("success"):
                groups = result.get("data", {}).get("groups", [])
                if groups:
                    print(f"📋 Found {len(groups)} machine groups:")
                    for group in groups:
                        print(f"  ID: {group['group_id']}, Name: {group['name']}")
                        if group.get('business_unit_id'):
                            print(f"    Business Unit: {group['business_unit_id']}")
                        if group.get('description'):
                            print(f"    Description: {group['description']}")
                        print()
                else:
                    print("📋 No machine groups found")
            else:
                print(f"❌ Failed to list machine groups: {result.get('message', 'Unknown error')}")
                sys.exit(1)
        
        elif args.command == "update":
            result = manager.update_machine_group(
                group_id=args.group_id,
                name=args.name,
                description=args.description,
                business_unit_id=args.business_unit_id,
                passphrase=args.passphrase
            )
            
            if result.get("success"):
                print(f"✅ Machine group {args.group_id} updated successfully!")
            else:
                print(f"❌ Failed to update machine group: {result.get('message', 'Unknown error')}")
                sys.exit(1)
        
        elif args.command == "delete":
            # Confirm deletion
            confirm = input(f"⚠️  Are you sure you want to delete machine group {args.group_id}? (y/N): ")
            if confirm.lower() not in ['y', 'yes']:
                print("❌ Deletion cancelled")
                sys.exit(0)
            
            result = manager.delete_machine_group(args.group_id)
            
            if result.get("success"):
                print(f"✅ Machine group {args.group_id} deleted successfully!")
                print("💡 All devices in this group have been moved to 'unassigned'")
            else:
                print(f"❌ Failed to delete machine group: {result.get('message', 'Unknown error')}")
                sys.exit(1)
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
