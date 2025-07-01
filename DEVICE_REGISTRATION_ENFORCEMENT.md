# Device Registration Enforcement - Implementation Summary

## Overview

The ReportMate system has been updated to enforce strict device registration. **Every event must now come from a registered device with a valid serial number.** The `/device/SERIAL` endpoint will only return data for properly registered devices.

## Key Changes Made

### 1. Events API (`apps/www/app/api/events/route.ts`)

**BEFORE:**
- Automatically accepted events from any device
- Used "upsert" logic to create phantom devices during event ingestion
- Device serial number was optional

**AFTER:**
- **Rejects events from unregistered devices** with HTTP 403
- **Requires device serial number** (HTTP 400 if missing)
- Checks device registration in database before accepting events
- Updates device `last_seen` timestamp on successful event ingestion

**Error Codes:**
- `400` - Device serial number missing
- `403` - Device not registered

### 2. Device Registration API (`apps/www/app/api/device/route.ts`)

**NEW:** Added POST method for device registration:
- Accepts device registration data (serial number, name, etc.)
- Stores device in production database
- Returns registration confirmation
- Supports device updates on re-registration

### 3. Device Lookup API (`apps/www/app/api/device/[deviceId]/route.ts`)

**ENHANCED:**
- **Checks production database first** for device existence
- Returns HTTP 404 if device not registered
- Falls back to mock data for additional device details if available
- Provides real event history from database
- Calculates device status based on `last_seen` timestamp

### 4. Windows Client Updates

#### New Registration Script (`clients/windows/Register-Device.ps1`)
- Automatically detects device serial number
- Collects device information (name, model, OS, etc.)
- Registers device with ReportMate server
- Marks registration status in Windows registry
- Supports force re-registration

#### Updated Collector (`clients/windows/ReportMate-Collector.ps1`)
- **Checks device registration before sending events**
- Uses device serial number instead of computer name
- Automatically attempts registration if device not registered
- Enhanced error handling for registration failures
- Updated endpoint from `/api/ingest` to `/api/events`

#### New Test Script (`clients/windows/Test-Registration-Flow.ps1`)
- Tests complete flow: registration check → registration → event sending
- Validates all error conditions
- Provides clear success/failure reporting

## Registration Flow

### For New Devices:

1. **Device Registration:**
   ```powershell
   .\Register-Device.ps1 -ServerUrl "http://localhost:3000" -Verbose
   ```

2. **Event Collection:**
   ```powershell
   .\ReportMate-Collector.ps1 -Verbose
   ```

### For Existing Deployments:

The collector now automatically handles registration:
- Checks if device is registered
- If not registered, runs registration automatically
- Only sends events after successful registration

## API Endpoints

### Register Device
```http
POST /api/device
Content-Type: application/json

{
  "serialNumber": "DEVICE-SERIAL",
  "name": "Device Name",
  "hostname": "hostname",
  "model": "Device Model",
  "os": "Operating System"
}
```

### Check Device Registration
```http
GET /api/device/DEVICE-SERIAL
```
- Returns `200` with device details if registered
- Returns `404` if device not registered

### Send Events (Now Enforced)
```http
POST /api/events
Content-Type: application/json

{
  "device": "DEVICE-SERIAL",  // REQUIRED - must be registered
  "kind": "event-type",
  "ts": "2024-01-01T10:00:00Z",
  "payload": { ... }
}
```
- Returns `403` if device not registered
- Returns `400` if device serial missing

## Testing

### Local Development Test:
```powershell
# Test complete registration and event flow
.\Test-Registration-Flow.ps1 -ServerUrl "http://localhost:3000" -Verbose

# Register a specific device
.\Register-Device.ps1 -ServerUrl "http://localhost:3000" -SerialNumber "TEST-DEVICE" -Verbose

# Send events (includes automatic registration check)
.\ReportMate-Collector.ps1 -Verbose
```

### Production Test:
```powershell
# Test against production
.\Test-Registration-Flow.ps1 -ServerUrl "https://reportmate.azurewebsites.net" -Verbose
```

## Database Schema

The enforcement relies on the existing `devices` table:
- `id` (TEXT PRIMARY KEY) - Device serial number
- `name` (TEXT) - Device name
- `created_at` (TIMESTAMP) - Registration time
- `updated_at` (TIMESTAMP) - Last update
- `last_seen` (TIMESTAMP) - Last event received

Events table:
- `device_id` (TEXT) - References `devices.id`
- Foreign key constraint ensures events can only reference registered devices

## Error Handling

### Client-Side:
- HTTP 403: Device not registered → Automatic registration attempt
- HTTP 400: Missing device serial → Script error
- HTTP 404: Device lookup failed → Device not found

### Server-Side:
- Database connection failures → Graceful fallback to mock data (read-only)
- Invalid device serial → Validation error
- Missing required fields → Detailed error messages

## Backwards Compatibility

- **Breaking Change:** Events from unregistered devices are now rejected
- **Migration Required:** Existing devices must be registered before they can send events
- **Automatic Handling:** The updated Windows client handles registration automatically

## Security Benefits

1. **Orphaned Event Prevention:** No more events from unknown/phantom devices
2. **Device Inventory Accuracy:** All events are tied to known, registered devices
3. **Audit Trail:** Clear registration and device lifecycle tracking
4. **Access Control:** Only registered devices can participate in the system

## Next Steps

1. **Deploy Updated APIs** to production environment
2. **Update Windows Clients** on all managed devices
3. **Bulk Register Existing Devices** using the registration script
4. **Monitor Registration Status** and event rejection logs
5. **Update Documentation** for device onboarding procedures

## Validation Commands

```powershell
# Check if device is registered
curl http://localhost:3000/api/device/YOUR-SERIAL

# Try to send event from unregistered device (should fail with 403)
curl -X POST http://localhost:3000/api/events -H "Content-Type: application/json" -d '{"device":"FAKE-DEVICE","kind":"test","payload":{}}'

# Register device and then send event (should succeed)
.\Register-Device.ps1 -SerialNumber "TEST-123"
curl -X POST http://localhost:3000/api/events -H "Content-Type: application/json" -d '{"device":"TEST-123","kind":"test","payload":{}}'
```

The system now enforces the requirement that **every event is tied to a registered device** and **`/device/SERIAL` always returns device details for registered devices**.
