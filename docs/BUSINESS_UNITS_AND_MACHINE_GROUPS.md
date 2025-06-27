# Business Units and Machine Groups

ReportMate supports organizational access control through **Business Units** and **Machine Groups**, inspired by MunkiReport's enterprise features. This system allows you to:

- Organize devices into logical groups with unique authentication keys
- Control user access to specific device groups
- Manage large deployments with role-based permissions
- Migrate from global passphrases to per-group authentication

## Overview

### Business Units
Business Units represent organizational divisions (departments, offices, teams) and can contain:
- **Machine Groups**: Collections of devices with shared passphrases
- **Users**: Individual user accounts with specific roles
- **Managers**: Users who can manage the business unit
- **Archivers**: Users who can archive devices
- **Groups**: LDAP/AD group assignments (prefixed with `@`)

### Machine Groups
Machine Groups organize devices that share a common passphrase:
- Each group has a **unique passphrase** (typically a GUID)
- Devices authenticate using their group's passphrase
- Groups can be assigned to Business Units for access control
- Unassigned groups are accessible to all admins

### Roles and Permissions

When Business Units are **disabled**:
| Role     | View         | Delete Machine | Archive Machine |
|----------|--------------|----------------|-----------------|
| admin    | All machines | Yes            | Yes             |
| manager  | All machines | Yes            | Yes             |
| archiver | All machines | No             | Yes             |
| user     | All machines | No             | No              |

When Business Units are **enabled**:
| Role     | View         | Delete Machine | Archive Machine | Edit Business Units |
|----------|--------------|----------------|-----------------|---------------------|
| admin    | All machines | Yes            | Yes             | Yes                 |
| manager  | BU only      | BU only        | Yes             | No                  |
| archiver | BU only      | No             | Yes             | No                  |
| user     | BU only      | No             | No              | No                  |
| nobody   | No machines  | No             | No              | No                  |

## Configuration

### Enable Business Units and Machine Groups

Add these variables to your Terraform configuration:

```hcl
# Enable business units for organizational access control
enable_business_units = true

# Enable per-machine-group passphrases
enable_machine_groups = true

# Optional: Keep legacy global passphrases for migration
client_passphrases = "legacy-key-1,legacy-key-2"
```

### Environment Variables

The following environment variables are set automatically by Terraform:

- `ENABLE_BUSINESS_UNITS`: Enable business unit functionality
- `ENABLE_MACHINE_GROUPS`: Enable per-group passphrase authentication
- `CLIENT_PASSPHRASES`: Legacy global passphrases (for migration)

## Database Schema

The enhanced schema includes these new tables:

```sql
-- Business Units
CREATE TABLE business_units (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    address TEXT,
    link TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Machine Groups with unique passphrases
CREATE TABLE machine_groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    passphrase_hash VARCHAR(64) UNIQUE NOT NULL, -- SHA-256 hash
    business_unit_id INTEGER REFERENCES business_units(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Business Unit User assignments
CREATE TABLE business_unit_users (
    id SERIAL PRIMARY KEY,
    business_unit_id INTEGER REFERENCES business_units(id) ON DELETE CASCADE,
    username VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user', -- user, manager, archiver, admin
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(business_unit_id, username)
);

-- Business Unit Group assignments (LDAP/AD groups)
CREATE TABLE business_unit_groups (
    id SERIAL PRIMARY KEY,
    business_unit_id INTEGER REFERENCES business_units(id) ON DELETE CASCADE,
    group_name VARCHAR(255) NOT NULL, -- Prefixed with @ (e.g., @ad_sales_team)
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(business_unit_id, group_name)
);

-- Devices are assigned to machine groups
ALTER TABLE devices ADD COLUMN machine_group_id INTEGER REFERENCES machine_groups(id);
```

## Creating Machine Groups

### Using the Management Script

```bash
# Create a machine group with generated GUID passphrase
python scripts/manage_machine_groups.py create \\
    --name "Sales Team" \\
    --description "Sales department devices" \\
    --generate-passphrase

# Create with custom passphrase
python scripts/manage_machine_groups.py create \\
    --name "IT Department" \\
    --passphrase "custom-secure-key-123"

# List all machine groups
python scripts/manage_machine_groups.py list

# Update a machine group
python scripts/manage_machine_groups.py update \\
    --group-id 1 \\
    --name "Sales Department" \\
    --description "Updated description"

# Delete a machine group (moves devices to unassigned)
python scripts/manage_machine_groups.py delete --group-id 1
```

### Using the API

```bash
# Create machine group
curl -X POST https://your-reportmate.azurewebsites.net/api/machine_groups \\
     -H "Content-Type: application/json" \\
     -d '{
       "action": "create",
       "name": "Engineering Team",
       "description": "Development and QA devices",
       "generate_passphrase": true
     }'

# List machine groups
curl -X POST https://your-reportmate.azurewebsites.net/api/machine_groups \\
     -H "Content-Type: application/json" \\
     -d '{"action": "list"}'
```

### Response Format

```json
{
  "success": true,
  "message": "Machine group 'Sales Team' created successfully",
  "data": {
    "group_id": 1,
    "name": "Sales Team",
    "description": "Sales department devices",
    "passphrase": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
    "passphrase_hash": "sha256_hash_here",
    "business_unit_id": null,
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

## Deploying Group Keys to Clients

### macOS Clients

```bash
# Set the machine group passphrase
sudo defaults write /Library/Preferences/ReportMate Passphrase 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'

# Verify the setting
defaults read /Library/Preferences/ReportMate Passphrase
```

### Windows Clients

Update your Group Policy template or deployment script:

```powershell
# Set registry value for machine group passphrase
Set-ItemProperty -Path "HKLM:\\SOFTWARE\\ReportMate" -Name "Passphrase" -Value "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
```

### Configuration Management

Deploy passphrases through your configuration management system:

**Ansible:**
```yaml
- name: Configure ReportMate machine group passphrase
  community.general.osx_defaults:
    domain: /Library/Preferences/ReportMate
    key: Passphrase
    type: string
    value: "{{ reportmate_group_passphrase }}"
  become: yes
```

**Puppet:**
```puppet
# macOS
exec { 'set_reportmate_passphrase':
  command => "/usr/bin/defaults write /Library/Preferences/ReportMate Passphrase '${reportmate_passphrase}'",
  unless  => "/usr/bin/defaults read /Library/Preferences/ReportMate Passphrase | grep -q '${reportmate_passphrase}'",
}
```

## Managing Business Units

### Creating Business Units

```bash
# Using the API
curl -X POST https://your-reportmate.azurewebsites.net/api/business_units \\
     -H "Content-Type: application/json" \\
     -d '{
       "action": "create",
       "name": "Sales Division",
       "description": "Regional sales teams",
       "address": "San Francisco, CA",
       "link": "https://company.com/sales",
       "users": ["john.doe", "jane.smith"],
       "managers": ["sales.manager"],
       "groups": ["@ad_sales_team"],
       "machine_groups": [1, 2, 3]
     }'
```

### Business Unit Structure

```json
{
  "unit_id": 1,
  "name": "Sales Division",
  "description": "Regional sales teams",
  "address": "San Francisco, CA",
  "link": "https://company.com/sales",
  "users": ["john.doe", "jane.smith"],
  "managers": ["sales.manager"],
  "archivers": ["archive.user"],
  "groups": ["@ad_sales_team", "@ldap_sales_managers"],
  "machine_groups": [1, 2, 3]
}
```

## Authentication Flow

### Per-Group Authentication (Recommended)

1. **Client sends data** with group passphrase
2. **Server hashes passphrase** (SHA-256)
3. **Database lookup** finds matching machine group
4. **Device assignment** to the machine group
5. **Access control** based on user's business unit membership

### Legacy Authentication (Migration)

1. **Client sends data** with global passphrase
2. **Server validates** against `CLIENT_PASSPHRASES`
3. **Device assigned** to default group (ID 0)
4. **Full access** for all authenticated users

### Migration Strategy

1. **Phase 1**: Enable both systems
   ```hcl
   enable_machine_groups = true
   client_passphrases = "legacy-key-1,legacy-key-2"  # Keep existing keys
   ```

2. **Phase 2**: Create machine groups and assign devices
   ```bash
   # Create groups for each department/location
   python scripts/manage_machine_groups.py create --name "IT Department" --generate-passphrase
   python scripts/manage_machine_groups.py create --name "Sales Team" --generate-passphrase
   ```

3. **Phase 3**: Deploy new passphrases to clients
   ```bash
   # Update client configurations with group-specific passphrases
   # Use configuration management or manual deployment
   ```

4. **Phase 4**: Disable legacy authentication
   ```hcl
   enable_machine_groups = true
   client_passphrases = ""  # Remove legacy keys
   ```

## Helper Functions

ReportMate provides helper functions similar to MunkiReport:

### `passphrase_to_group_id(passphrase_hash)`
Lookup machine group ID by passphrase hash.

### `authorized_for_serial(serial_number)`
Check if current user can access data for a specific device.

### `get_machine_group_filter()`
Generate SQL WHERE clause for machine group filtering.

### `get_machine_group(serial_number)`
Get machine group ID for a specific device.

## Security Considerations

### Passphrase Management
- **Unique per group**: Each machine group has its own passphrase
- **GUID format**: Use UUID-style passphrases for security
- **Secure storage**: Passphrases are hashed (SHA-256) in database
- **Rotation**: Update passphrases regularly and redeploy to clients

### Access Control
- **Principle of least privilege**: Users only see their business unit's devices
- **Role-based permissions**: Different capabilities for user/manager/archiver
- **Group inheritance**: LDAP/AD group memberships automatically grant access

### Database Security
- **Never store plaintext**: Only SHA-256 hashes are stored
- **Indexed lookups**: Fast passphrase validation
- **Audit trails**: Track group assignments and changes

## Troubleshooting

### Common Issues

**"Unauthorized: Invalid or missing passphrase"**
- Check client passphrase configuration
- Verify passphrase matches a machine group
- Ensure machine groups are enabled

**"Device not showing in business unit"**
- Check device's machine group assignment
- Verify machine group is assigned to business unit
- Confirm user has appropriate role

**"User cannot see any devices"**
- Check user's business unit membership
- Verify user role (user/manager/archiver)
- Ensure business units are properly configured

### Debug Commands

```bash
# Check machine group configuration
python scripts/manage_machine_groups.py list

# Test API connectivity
curl -X POST https://your-reportmate.azurewebsites.net/api/machine_groups \\
     -H "Content-Type: application/json" \\
     -d '{"action": "list"}'

# Verify client passphrase
defaults read /Library/Preferences/ReportMate Passphrase  # macOS
```

### Log Analysis

Check Azure Function logs for authentication errors:

```bash
# Using Azure CLI
az functionapp logs tail --name your-reportmate-functions --resource-group your-rg

# Look for these log patterns:
# "Machine group mode: validating passphrase hash..."
# "Legacy passphrase mode: passphrase validated"
# "Unauthorized access attempt from device..."
```

## Migration from MunkiReport

If migrating from MunkiReport, you can import existing machine groups:

1. **Export MunkiReport groups**:
   ```sql
   SELECT groupid, property, value 
   FROM machine_group 
   WHERE property IN ('name', 'key');
   ```

2. **Create equivalent ReportMate groups**:
   ```bash
   # For each MunkiReport group
   python scripts/manage_machine_groups.py create \\
     --name "Group Name" \\
     --passphrase "existing-key-from-munkireport"
   ```

3. **Update client configurations** with ReportMate endpoints and preserve existing passphrases

## Best Practices

### Organization
- **Logical grouping**: Group devices by department, location, or function
- **Descriptive names**: Use clear, descriptive machine group names
- **Business unit alignment**: Align groups with organizational structure

### Security
- **Regular rotation**: Update passphrases periodically
- **Secure distribution**: Use encrypted channels for passphrase deployment
- **Access reviews**: Regularly review business unit memberships

### Operations
- **Monitoring**: Track authentication failures and group assignments
- **Documentation**: Document group purposes and membership
- **Automation**: Use scripts for bulk operations

This system provides enterprise-grade device organization and access control while maintaining the simplicity and reliability that makes ReportMate effective for device management.
