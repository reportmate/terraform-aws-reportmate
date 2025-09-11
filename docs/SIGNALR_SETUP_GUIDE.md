# SignalR Setup Guide for ReportMate

## Current Status: ❌ Not Configured

Your ReportMate dashboard is currently using **HTTP polling** instead of real-time SignalR connections because the backend SignalR infrastructure is not set up.

## Why You Only See "Polling" Status

1. **Missing API Endpoint**: The `/api/negotiate` endpoint doesn't exist in your Azure Functions API
2. **Environment Variable**: `NEXT_PUBLIC_ENABLE_SIGNALR=false` in your `.env.local`
3. **No WebPubSub Service**: Azure WebPubSub service is not configured or connected

## Current Polling vs SignalR

| Feature | HTTP Polling (Current) | SignalR (Target) |
|---------|----------------------|------------------|
| **Update Frequency** | Every 10 seconds | Instant |
| **Server Load** | Higher (constant requests) | Lower (persistent connection) |
| **Latency** | 0-10 seconds delay | <1 second |
| **Reliability** | Good (HTTP standard) | Excellent (auto-reconnect) |
| **Bandwidth** | Higher | Lower |

## How to Enable SignalR (When Ready)

### Step 1: Backend API Setup

You need to add a `/api/negotiate` endpoint to your Azure Functions that returns SignalR connection info:

```javascript
// Azure Function: negotiate/index.js
const { app } = require('@azure/functions');

app.http('negotiate', {
    methods: ['GET'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        // This should connect to Azure WebPubSub or SignalR service
        return {
            jsonBody: {
                url: 'wss://your-webpubsub.webpubsub.azure.com/client/hubs/fleet',
                accessToken: 'your-jwt-token'
            }
        };
    }
});
```

### Step 2: Azure WebPubSub Service

1. **Create Azure WebPubSub** service in your resource group
2. **Configure Hub Settings** with name `fleet`
3. **Get Connection String** and add to Azure Functions configuration
4. **Set up Event Handlers** to push events to connected clients

### Step 3: Environment Configuration

Update your `.env.local`:

```bash
# Enable SignalR
NEXT_PUBLIC_ENABLE_SIGNALR=true

# Optional: Direct WebPubSub URL (if not using negotiate)
NEXT_PUBLIC_WPS_URL=wss://your-webpubsub.webpubsub.azure.com/client/hubs/fleet
NEXT_PUBLIC_WPS_TOKEN=your-jwt-token
```

### Step 4: Infrastructure as Code

Your Terraform files in `/infrastructure` already include WebPubSub configuration:

```hcl
# messaging.tf
resource "azurerm_web_pubsub" "signalr" {
  name                = "reportmate-signalr"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  # ... configuration
}
```

Run `terraform apply` to create the WebPubSub service.

## Testing SignalR Setup

1. **Check negotiate endpoint**:
   ```bash
   curl https://reportmate-api.azurewebsites.net/api/negotiate?device=test
   ```
   Should return: `{"url": "wss://...", "accessToken": "..."}`

2. **Enable in environment**:
   ```bash
   NEXT_PUBLIC_ENABLE_SIGNALR=true
   ```

3. **Watch browser console** for SignalR connection logs

4. **Dashboard status** should show "Live" instead of "Polling"

## Benefits of Enabling SignalR

- **Instant notifications** when devices check in
- **Real-time event streaming** without page refresh
- **Better user experience** with live updates
- **Reduced server load** from constant polling
- **Lower bandwidth usage** for users

## Current Workaround

The polling mechanism works well and provides:
- ✅ All event data is still received
- ✅ Dashboard updates every 10 seconds
- ✅ No data loss or missing information
- ✅ Reliable operation without additional infrastructure

**Recommendation**: Keep polling for now since it's working reliably, and implement SignalR when you have time to set up the full Azure WebPubSub infrastructure.

## Monitoring Current Setup

The dashboard includes:
- **Performance Monitor** (development mode) - shows memory usage
- **SignalR Status Component** (development mode) - shows connection details
- **Connection status indicator** - blue "Polling" badge in Recent Events

All of these help monitor the current HTTP polling setup and will automatically show SignalR status when it becomes available.
