# Migration to Business Units and Machine Groups

This guide helps you migrate from ReportMate's basic authentication to the advanced business units and machine groups system.

## Migration Overview

The migration process moves from:
- **Current**: Single global passphrase for all devices
- **Target**: Unique passphrases per machine group with business unit organization

## Prerequisites

- ReportMate deployment with basic authentication
- Admin access to modify Terraform configuration
- Access to client device configuration management

## Migration Steps

### Phase 1: Enable Advanced Features

Update your Terraform configuration to enable both systems during transition:

```hcl
# terraform.tfvars
client_passphrases = "existing-global-key"  # Keep current key
enable_machine_groups = true                # Enable new system
enable_business_units = true                # Enable organization features
```

Apply the changes:
```bash
terraform plan
terraform apply
```

This enables both authentication methods simultaneously for zero-downtime migration.

### Phase 2: Plan Your Organization

Design your machine groups and business units structure:

#### Example Organization
```
Sales Division (Business Unit)
├── Sales Team East (Machine Group)
├── Sales Team West (Machine Group)
└── Sales Management (Machine Group)

IT Division (Business Unit)
├── Desktop Support (Machine Group)
├── Infrastructure (Machine Group)
└── Development (Machine Group)
```

#### Consider These Factors
- **Geographic distribution**: Group by office/region
- **Organizational structure**: Align with departments
- **Management requirements**: Who needs access to what
- **Device types**: Separate servers, workstations, mobile devices

### Phase 3: Create Machine Groups

Use the management script to create machine groups:

```bash
# Create groups for each logical division
python scripts/manage_machine_groups.py create \\
    --name "Sales Team East" \\
    --description "East coast sales team devices" \\
    --generate-passphrase

python scripts/manage_machine_groups.py create \\
    --name "IT Infrastructure" \\
    --description "Server and network infrastructure" \\
    --generate-passphrase

# List all groups to verify
python scripts/manage_machine_groups.py list
```

**Save the passphrases** generated for each group - you'll need them for client deployment.

### Phase 4: Create Business Units

Create business units and assign machine groups:

```bash
curl -X POST https://your-reportmate.azurewebsites.net/api/business_units \\
     -H "Content-Type: application/json" \\
     -d '{
       "action": "create",
       "name": "Sales Division",
       "description": "Regional sales operations",
       "users": ["sales.manager", "regional.director"],
       "managers": ["sales.manager"],
       "machine_groups": [1, 2]
     }'
```

### Phase 5: Deploy New Passphrases

Deploy the new machine group passphrases to clients in batches:

#### Batch Deployment Strategy

1. **Start with pilot groups** (IT team devices)
2. **Gradual rollout** by department
3. **Monitor authentication logs** for issues
4. **Rollback capability** using legacy passphrase

#### Configuration Management Examples

**Ansible Playbook:**
```yaml
---
- name: Deploy ReportMate machine group passphrases
  hosts: "{{ target_group }}"
  vars:
    machine_group_passphrases:
      it_infrastructure: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
      sales_east: "B2C3D4E5-F6G7-8901-BCDE-F23456789012"
      sales_west: "C3D4E5F6-G7H8-9012-CDEF-345678901234"
  
  tasks:
    - name: Set ReportMate passphrase (macOS)
      community.general.osx_defaults:
        domain: /Library/Preferences/ReportMate
        key: Passphrase
        type: string
        value: "{{ machine_group_passphrases[group_name] }}"
      become: yes
      when: ansible_os_family == "Darwin"
    
    - name: Set ReportMate passphrase (Windows)
      win_regedit:
        path: HKLM:\\SOFTWARE\\ReportMate
        name: Passphrase
        data: "{{ machine_group_passphrases[group_name] }}"
        type: string
      when: ansible_os_family == "Windows"
```

**Group Policy (Windows):**
```xml
<!-- Administrative Template -->
<policy name="ReportMate_Passphrase" 
        class="Machine" 
        displayName="ReportMate Authentication Passphrase"
        explainText="Configure the machine group passphrase for ReportMate reporting">
  <parentCategory ref="ReportMate"/>
  <supportedOn ref="SUPPORTED_Win7"/>
  <elements>
    <text id="Passphrase" valueName="Passphrase" required="true"/>
  </elements>
</policy>
```

#### Manual Deployment (Small Environments)

```bash
# macOS - Deploy via script
#!/bin/bash
DEVICE_GROUP="$1"
case "$DEVICE_GROUP" in
    "sales-east")
        PASSPHRASE="A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        ;;
    "it-infra")
        PASSPHRASE="B2C3D4E5-F6G7-8901-BCDE-F23456789012"
        ;;
    *)
        echo "Unknown device group: $DEVICE_GROUP"
        exit 1
        ;;
esac

sudo defaults write /Library/Preferences/ReportMate Passphrase "$PASSPHRASE"
echo "ReportMate passphrase updated for group: $DEVICE_GROUP"
```

### Phase 6: Monitor Migration

Track the migration progress:

#### Azure Function Logs
```bash
# Monitor authentication patterns
az functionapp logs tail --name your-reportmate-functions --resource-group your-rg

# Look for log entries:
# "Machine group mode: validating passphrase hash..."  # New system
# "Legacy passphrase mode: passphrase validated"      # Old system
```

#### Device Assignment Dashboard
Query the database to see device group assignments:

```sql
-- Check device distribution across machine groups
SELECT 
    mg.name as group_name,
    COUNT(d.id) as device_count,
    bu.name as business_unit
FROM machine_groups mg
LEFT JOIN devices d ON mg.id = d.machine_group_id
LEFT JOIN business_units bu ON mg.business_unit_id = bu.id
GROUP BY mg.id, mg.name, bu.name
ORDER BY device_count DESC;

-- Devices still using legacy authentication (group_id is NULL)
SELECT COUNT(*) as legacy_devices
FROM devices 
WHERE machine_group_id IS NULL;
```

### Phase 7: Validate Access Control

Test business unit access control:

#### User Access Testing
1. **Login as different users** to verify they only see appropriate devices
2. **Test role permissions** (user vs manager vs archiver)
3. **Verify LDAP/AD group integration** if configured

#### API Testing
```bash
# Test business unit filtering
curl -X POST https://your-reportmate.azurewebsites.net/api/business_units \\
     -H "Content-Type: application/json" \\
     -d '{"action": "list"}'

# Test machine group access
python scripts/manage_machine_groups.py list --business-unit-id 1
```

### Phase 8: Remove Legacy Authentication

Once all devices are migrated to machine groups:

```hcl
# terraform.tfvars - Remove legacy authentication
client_passphrases = ""                     # Disable legacy keys
enable_machine_groups = true                # Keep new system
enable_business_units = true                # Keep organization features
```

Apply the final configuration:
```bash
terraform plan  # Verify only legacy auth is being removed
terraform apply
```

## Rollback Procedures

### Emergency Rollback

If issues occur during migration, quickly restore legacy authentication:

```hcl
# terraform.tfvars - Emergency rollback
client_passphrases = "original-global-key"  # Restore legacy auth
enable_machine_groups = false               # Disable new system
enable_business_units = false               # Disable organization features
```

```bash
terraform apply -auto-approve  # Quick deployment
```

### Partial Rollback

Rollback specific device groups while maintaining others:

1. **Update client configuration** to use legacy passphrase
2. **Remove from machine group** via management script
3. **Monitor logs** to confirm devices are using legacy auth

```bash
# Remove devices from machine group (they'll use legacy auth)
python scripts/manage_machine_groups.py delete --group-id 5
```

## Troubleshooting

### Common Issues

**"Device not appearing in business unit"**
- Check machine group assignment
- Verify business unit contains the machine group
- Confirm user has appropriate business unit access

**"Authentication failures after migration"**
- Verify passphrase deployment completed
- Check for typos in deployed passphrases
- Confirm machine group exists in database

**"Users can't see any devices"**
- Check business unit user assignments
- Verify user roles are correct
- Ensure business units are enabled

### Debugging Commands

```bash
# Check device authentication mode
grep "auth_mode" /path/to/azure-function-logs

# Verify client configuration
defaults read /Library/Preferences/ReportMate Passphrase  # macOS
Get-ItemProperty "HKLM:\\SOFTWARE\\ReportMate" -Name "Passphrase"  # Windows

# Test API connectivity
curl -X POST https://your-reportmate.azurewebsites.net/api/ingest \\
     -H "Content-Type: application/json" \\
     -d '{
       "device": "test-device",
       "kind": "test",
       "passphrase": "your-group-passphrase",
       "payload": {}
     }'
```

## Migration Checklist

### Pre-Migration
- [ ] Document current authentication setup
- [ ] Plan machine group structure
- [ ] Design business unit organization
- [ ] Prepare deployment scripts/policies
- [ ] Schedule maintenance window
- [ ] Prepare rollback procedures

### During Migration
- [ ] Enable both authentication systems
- [ ] Create machine groups
- [ ] Create business units
- [ ] Deploy new passphrases in batches
- [ ] Monitor authentication logs
- [ ] Validate device assignments
- [ ] Test user access control

### Post-Migration
- [ ] Remove legacy authentication
- [ ] Document new group structure
- [ ] Update operational procedures
- [ ] Train administrators on new features
- [ ] Schedule regular access reviews

## Best Practices

### Planning
- **Start small**: Begin with IT team devices as pilots
- **Document everything**: Record group purposes and passphrases
- **Test thoroughly**: Validate access control before full rollout

### Security
- **Rotate passphrases**: Plan regular passphrase updates
- **Secure storage**: Store passphrases in password managers
- **Principle of least privilege**: Assign minimal necessary permissions

### Operations
- **Monitor continuously**: Track authentication patterns and failures
- **Automate management**: Use scripts for bulk operations
- **Regular reviews**: Audit business unit memberships quarterly

This migration approach ensures zero downtime while transitioning to the advanced organizational features that enable enterprise-scale device management with proper access control.
