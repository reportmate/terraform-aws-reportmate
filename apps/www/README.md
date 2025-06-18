# Seemianki Web Dashboard

A Next.js-based real-time dashboard for monitoring fleet events via SignalR.

## Setup

1. Copy the environment template:

```bash
cp .env.local.example .env.local
```

2. Fill in your Azure Web PubSub connection details in `.env.local`:

```
NEXT_PUBLIC_WPS_URL=wss://<your-pubsub>.webpubsub.azure.com/client/?hub=fleet
NEXT_PUBLIC_WPS_TOKEN=<jwt-from-/api/negotiate>
```

## Development

```bash
# Install dependencies (from project root)
pnpm install

# Start development server
pnpm dev

# Visit http://localhost:3000/dashboard
```

## Features

- Real-time event streaming via SignalR
- Live dashboard with event history
- Dark theme with Tailwind CSS
- TypeScript support
- Automatic reconnection

## Testing

Post a test event to your ingest function:

```bash
curl -X POST https://<functionapp>.azurewebsites.net/api/ingest \
  -H "Content-Type: application/json" \
  -d '{"device":"web-test","kind":"ping","payload":{}}'
```

The event should appear instantly in the dashboard.
