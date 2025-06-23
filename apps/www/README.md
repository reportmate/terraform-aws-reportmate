# Reportmate Web Dashboard

A Next.js-based real-time dashboard for monitoring fleet events via SignalR, inspired by the MunkiReport event module design.

## ✨ Features

- **Real-time Event Streaming** via SignalR with automatic reconnection
- **Professional Dashboard UI** inspired by MunkiReport's event module
- **Status-based Event Display** with color-coded indicators and icons
- **Smart Payload Formatting** that adapts to different data types
- **Live Connection Status** with visual indicators
- **Modern Design** with glassmorphism effects and smooth animations
- **Responsive Layout** that works on all screen sizes
- **Dark Theme** optimized for monitoring environments

## 🚀 Quick Start

### 1. Setup Environment

```bash
cp .env.local.example .env.local
```

Fill in your Azure Web PubSub connection details in `.env.local`:

```env
NEXT_PUBLIC_WPS_URL=wss://<your-pubsub>.webpubsub.azure.com/client/?hub=fleet
NEXT_PUBLIC_WPS_TOKEN=<jwt-from-/api/negotiate>
NEXT_PUBLIC_API_BASE_URL=https://reportmate-api.azurewebsites.net
```

### 2. Install Dependencies

```bash
# From project root
pnpm install
```

### 3. Start Development Server

```bash
pnpm dev
```

Visit **http://localhost:3000/dashboard** to see the dashboard.

## 🧪 Testing & Demo Data

### API Testing

Test the local events API:
```bash
# Get events
curl -X GET http://localhost:3000/api/events

# Post an event
curl -X POST http://localhost:3000/api/events \
  -H "Content-Type: application/json" \
  -d '{"device":"test-device","kind":"info","payload":{"message":"Hello World"}}'

# Test Azure Functions integration
curl -X GET http://localhost:3000/api/test
```

### Demo Data Generation

Generate sample events for testing the dashboard:

```bash
# Generate 10 events with 2-second intervals (default)
pnpm demo

# Generate 20 events quickly (1-second intervals)
pnpm demo:fast

# Generate 5 events slowly (5-second intervals)
pnpm demo:slow

# Custom: 15 events with 500ms intervals
node scripts/demo-data.js 15 500
```

## 🎨 Dashboard Features

### Event Types & Visual Indicators

| Type | Icon | Description |
|------|------|-------------|
| `error` | ❌ | Red indicators for critical issues |
| `warning` | ⚠️ | Yellow indicators for warnings |
| `success` | ✅ | Green indicators for successful operations |
| `info` | ℹ️ | Blue indicators for informational messages |
| `ping` | 🔄 | Purple indicators for heartbeats/pings |
| `system` | 🔧 | Gray indicators for system events |

### Smart Payload Display

The dashboard intelligently formats event payloads:

- **Simple Messages**: Shows directly in the table
- **Key-Value Pairs** (≤3 items): Displays as a clean list
- **Complex Objects**: Shows expandable JSON with item count
- **Error Messages**: Highlights errors in red

### Connection Status

| Status | Indicator | Description |
|--------|-----------|-------------|
| Connected | 🟢 Pulsing | Live SignalR connection active |
| Connecting | 🟡 Pulsing | Establishing connection |
| Reconnecting | 🟠 Pulsing | Attempting to reconnect |
| Offline | 🔴 Static | Connection failed |
| Dev Mode | ⚪ Static | SignalR disabled for development |

## 🔧 Development

### File Structure

```
apps/www/
├── app/
│   ├── api/
│   │   ├── events/route.ts      # Local events storage API
│   │   └── test/route.ts        # Azure Functions test API
│   ├── dashboard/
│   │   ├── page.tsx             # Main dashboard component
│   │   └── hooks.ts             # SignalR connection logic
│   ├── globals.css              # Global styles
│   └── layout.tsx               # App layout
├── scripts/
│   └── demo-data.js             # Demo data generator
└── README.md                    # This file
```

### Adding New Event Types

1. Update the `getStatusIcon()` function in `dashboard/page.tsx`
2. Add color mapping in `getStatusColorClass()`
3. Update the demo data generator in `scripts/demo-data.js`

### Customizing the UI

The dashboard uses Tailwind CSS with a dark theme optimized for monitoring:

- **Primary Colors**: Blue (`blue-600`, `blue-500`)
- **Background**: Gradient from `slate-900` to `slate-800`
- **Cards**: `slate-800/30` with backdrop blur
- **Text**: White headings, `slate-300` body, `slate-400` muted

## 🌐 Production Deployment

### Building for Production

```bash
pnpm build
```

### Environment Variables

For production, set these in your hosting environment:

```env
NEXT_PUBLIC_WPS_URL=wss://your-pubsub.webpubsub.azure.com/client/hubs/fleet
NEXT_PUBLIC_ENABLE_SIGNALR=true
NEXT_PUBLIC_API_BASE_URL=https://your-function-app.azurewebsites.net
```

### Azure Static Web Apps

The app is configured for Azure Static Web Apps deployment:

```bash
# Deploy using SWA CLI
npx @azure/static-web-apps-cli deploy \
  --app-location "." \
  --output-location "out" \
  --deployment-token "$AZURE_STATIC_WEB_APPS_API_TOKEN"
```

## 🧩 Integration with Azure

### SignalR Connection

The dashboard connects to Azure Web PubSub via the `/api/negotiate` endpoint:

1. Fetches authentication token from Azure Functions
2. Establishes WebSocket connection to Azure Web PubSub
3. Listens for real-time event broadcasts
4. Automatically reconnects on connection loss

### Event Ingestion

Events flow through this architecture:

```
Client/Device → Azure Function (ingest) → Azure Web PubSub → Dashboard
                     ↓
               PostgreSQL Database
```

### Event Schema

```typescript
interface FleetEvent {
  id: string                          // Unique event identifier
  device: string                      // Source device name
  kind: string                        // Event type (error, warning, etc.)
  ts: string                          // ISO timestamp
  payload: Record<string, unknown>    // Event data
}
```

## 🔍 Troubleshooting

### Common Issues

**SignalR Connection Failed**
- Check Azure Web PubSub configuration
- Verify negotiate endpoint returns valid tokens
- Ensure CORS is properly configured

**Events Not Appearing**
- Check browser console for JavaScript errors
- Verify API endpoints are responding
- Test with manual event posting

**Build Errors**
- Ensure all dependencies are installed: `pnpm install`
- Check TypeScript errors: `pnpm lint`
- Verify environment variables are set

### Debug Mode

Enable debug logging by opening browser console and setting:

```javascript
localStorage.setItem('debug', 'true')
```

This will show detailed SignalR connection logs and event processing information.

---

**Dashboard inspired by**: [MunkiReport Event Module](https://github.com/munkireport/event)  
**Built with**: Next.js 15, React 18, TypeScript, Tailwind CSS, SignalR
