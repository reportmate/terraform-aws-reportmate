# 🔐 ReportMate Client Authentication

ReportMate supports optional passphrase-based authentication to restrict access to the reporting endpoints. This document covers the basic passphrase authentication system.

> **🆕 Enterprise Features**: For advanced organizational features including per-machine-group passphrases, business units, and role-based access control, see [Business Units and Machine Groups](BUSINESS_UNITS_AND_MACHINE_GROUPS.md).

ReportMate provides multiple authentication approaches:

1. **Open Access** - No authentication (development/testing)
2. **Global Passphrases** - Shared passphrases (documented here)
3. **Per-Group Passphrases** - Unique keys per machine group (enterprise feature)

## Server Configuration

### Environment Variable

Add client passphrases to the `CLIENT_PASSPHRASES` environment variable:

```bash
CLIENT_PASSPHRASES="mysecretpassphrase,myotherpassphrase,thirdpassphrase"
```

### Azure Deployment

For Azure deployments, configure this in your `terraform.tfvars`:

```hcl
client_passphrases = "mysecretpassphrase,myotherpassphrase"
```

### Local Development

For local development, add to your `.env` file:

```bash
CLIENT_PASSPHRASES=mysecretpassphrase,myotherpassphrase
```

### Security Notes

- **If no passphrases are configured**, ReportMate accepts all client requests (open mode)
- **If passphrases are configured**, only clients with valid passphrases can submit data
- Multiple passphrases can be configured (comma-separated) for key rotation
- Passphrases are case-sensitive and whitespace is trimmed

## Client Configuration

### JSON Payload

Clients must include the `passphrase` field in their JSON payload:

```json
{
  "device": "my-device-001",
  "kind": "osquery_info",
  "passphrase": "mysecretpassphrase",
  "payload": {
    "system_info": {
      "hostname": "my-device-001",
      "platform": "darwin"
    }
  }
}
```

### Windows Client (Group Policy)

Configure via Registry/Group Policy using OMA-URI:

```
OMA-URI: ./Device/Vendor/MSFT/Registry/HKLM/SOFTWARE/Policies/ReportMate/Passphrase
Data type: String
Value: mysecretpassphrase
```

### macOS Client (MDM)

Configure via MDM profile or local configuration:

```sh
# Local configuration
defaults write /Library/Preferences/ReportMate Passphrase 'mysecretpassphrase'

# Or via configuration profile
<key>Passphrase</key>
<string>mysecretpassphrase</string>
```

### Linux Client

Configure via environment variable or configuration file:

```bash
# Environment variable
export REPORTMATE_PASSPHRASE="mysecretpassphrase"

# Or in /etc/reportmate/config
echo "passphrase=mysecretpassphrase" > /etc/reportmate/config
```

## Client Implementation

### Windows Client (Automated)

ReportMate includes a complete Windows client implementation with automated installation and configuration:

```powershell
# Quick installation with authentication
.\Install-ReportMate.ps1 -ServerUrl "https://reportmate-api.azurewebsites.net" -Passphrase "mysecretpassphrase"

# Test configuration
.\ReportMate-Collector.ps1 -TestMode

# View current configuration
.\ReportMate-Setup.ps1 -ShowConfiguration
```

**Features:**

- Automated osquery data collection
- Windows Task Scheduler integration
- Group Policy template (`.adm` file)
- Event log integration
- Registry-based configuration
- MDM/Intune support via OMA-URI

**Files included:**

- `Install-ReportMate.ps1` - Complete installer
- `ReportMate-Collector.ps1` - Data collection script
- `ReportMate-Setup.ps1` - Configuration utility
- `ReportMate.adm` - Group Policy template
- `osquery.conf` - Example osquery configuration

See [`clients/windows/README.md`](../clients/windows/README.md) for detailed deployment instructions.

## API Response Codes

| Status Code | Description |
|-------------|-------------|
| `202` | Request accepted successfully |
| `400` | Invalid JSON payload |
| `401` | Unauthorized - Invalid or missing passphrase |
| `500` | Internal server error |

## Security Considerations

### Best Practices

1. **Use strong passphrases**: Minimum 16 characters with mixed case, numbers, and symbols
2. **Regular rotation**: Change passphrases periodically
3. **Secure distribution**: Use MDM/Group Policy to distribute passphrases, not installation scripts
4. **Monitor access**: Check Application Insights for unauthorized access attempts
5. **Principle of least privilege**: One passphrase per client when possible

### Key Rotation Strategy

1. **Add new passphrase** to the comma-separated list
2. **Deploy updated configuration** to all environments
3. **Update clients** to use the new passphrase
4. **Remove old passphrase** after all clients are updated

Example rotation:

```bash
# Step 1: Add new passphrase
CLIENT_PASSPHRASES="oldpassphrase,newpassphrase"

# Step 2: After client updates, remove old
CLIENT_PASSPHRASES="newpassphrase"
```

### Monitoring

Check Azure Application Insights for:

- `401` responses indicating unauthorized access attempts
- Log entries showing passphrase validation failures
- Unusual patterns in client authentication

## Testing

### Test Authentication

```bash
# Test with valid passphrase
curl -X POST "https://your-function-app.azurewebsites.net/api/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "device": "test-device",
    "kind": "test",
    "passphrase": "mysecretpassphrase",
    "payload": {"test": true}
  }'

# Test without passphrase (should fail if authentication enabled)
curl -X POST "https://your-function-app.azurewebsites.net/api/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "device": "test-device",
    "kind": "test",
    "payload": {"test": true}
  }'
```

### Disable Authentication

To disable authentication (allow all clients), set an empty value:

```bash
CLIENT_PASSPHRASES=""
# or remove the environment variable entirely
```

## Migration Strategy

### From Open to Authenticated

1. **Phase 1**: Deploy with empty `CLIENT_PASSPHRASES` (maintains current behavior)
2. **Phase 2**: Configure client passphrases via MDM/Group Policy
3. **Phase 3**: Enable server-side authentication by setting `CLIENT_PASSPHRASES`
4. **Phase 4**: Monitor and validate all clients are working

### Rollback Plan

If issues occur, immediately set `CLIENT_PASSPHRASES=""` to restore open access while troubleshooting client configurations.
