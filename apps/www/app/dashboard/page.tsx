"use client"

import React from "react"
import { useLiveEvents, type FleetEvent } from "@/src/lib/signalr"
import "@/app/globals.css"

export default function Dashboard(): React.JSX.Element {
  const { events, connectionStatus, addEvent } = useLiveEvents()

  // Function to manually add events for testing
  const [localEvents, setLocalEvents] = React.useState<FleetEvent[]>([])
  const allEvents = [...events, ...localEvents]

  function addLocalEvent(event: FleetEvent) {
    setLocalEvents(prev => [event, ...prev])
  }

  // Function to send a test event
  async function sendTestEvent() {
    try {
      console.log("🧪 Sending test event...")
      const testPayload = {
        device: 'dashboard-test',
        kind: 'ping',
        payload: { 
          test: true, 
          timestamp: new Date().toISOString(),
          source: 'dashboard-ui',
          testId: Date.now()
        }
      }
      
      // Use the local API route instead of calling Azure Function directly (CORS issue)
      const response = await fetch('/api/test', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })
      
      if (response.ok) {
        console.log('✅ Test event sent successfully')
        // Add a local confirmation event
        const confirmEvent: FleetEvent = {
          id: `confirm-${Date.now()}`,
          device: 'dashboard-client',
          kind: 'info',
          ts: new Date().toISOString(),
          payload: { message: 'Test event sent to ingest API', testPayload }
        }
        // This is a hack to show the confirmation - in real app this would come via SignalR
        addLocalEvent(confirmEvent)
      } else {
        console.error('❌ Failed to send test event:', response.status)
        throw new Error(`HTTP ${response.status}`)
      }
    } catch (error) {
      console.error('❌ Error sending test event:', error)
      const errorEvent: FleetEvent = {
        id: `error-${Date.now()}`,
        device: 'dashboard-client',
        kind: 'error',
        ts: new Date().toISOString(),
        payload: { error: (error as Error).message, action: 'send_test_event' }
      }
      addLocalEvent(errorEvent)
    }
  }

  return (
    <main className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Seemianki Fleet Dashboard</h1>
        <div className="flex items-center space-x-4">
          <button 
            onClick={sendTestEvent}
            className="px-3 py-1 bg-blue-600 hover:bg-blue-700 rounded text-sm transition-colors"
          >
            Send Test Event
          </button>
          <div className="flex items-center space-x-2">
            <div className={`w-3 h-3 rounded-full ${
              connectionStatus === 'connected' ? 'bg-green-500 animate-pulse' :
              connectionStatus === 'connecting' ? 'bg-yellow-500 animate-pulse' :
              connectionStatus === 'reconnecting' ? 'bg-orange-500 animate-pulse' :
              connectionStatus === 'polling' ? 'bg-blue-500 animate-pulse' :
              connectionStatus === 'disabled' ? 'bg-gray-500' :
              'bg-red-500'
            }`}></div>
            <span className="text-sm text-slate-400">
              {connectionStatus === 'error' ? 'SignalR Offline' : 
               connectionStatus === 'disabled' ? 'SignalR Dev Mode' : 
               connectionStatus === 'polling' ? 'API Polling' :
               connectionStatus} ({allEvents.length} events)
              {connectionStatus === 'error' && (
                <span className="text-xs text-slate-500 block">
                  Manual events work, real-time pending
                </span>
              )}
              {connectionStatus === 'disabled' && (
                <span className="text-xs text-slate-500 block">
                  Live events disabled in development
                </span>
              )}
              {connectionStatus === 'polling' && (
                <span className="text-xs text-slate-500 block">
                  Fetching events via API every 5s
                </span>
              )}
            </span>
          </div>
        </div>
      </div>

      <div className="bg-slate-800 rounded-lg overflow-hidden shadow-lg">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-700">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                  Timestamp
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                  Device
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                  Event Type
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                  Payload
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                  Status
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-600">
              {allEvents.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-slate-400">
                    <div className="flex flex-col items-center space-y-2">
                      <div className="w-8 h-8 border-2 border-slate-500 border-t-blue-500 rounded-full animate-spin"></div>
                      <span>Waiting for events...</span>
                      <span className="text-xs">Connection status: {connectionStatus}</span>
                    </div>
                  </td>
                </tr>
              ) : (
                [...allEvents].reverse().map((event, index) => (
                  <tr 
                    key={event.id || index} 
                    className={`hover:bg-slate-700 transition-colors ${
                      index === 0 ? 'bg-slate-700/50' : ''
                    }`}
                  >
                    <td className="px-4 py-3 text-sm text-slate-300">
                      <div className="flex flex-col">
                        <span className="font-mono">
                          {new Date(event.ts).toLocaleTimeString()}
                        </span>
                        <span className="text-xs text-slate-500">
                          {new Date(event.ts).toLocaleDateString()}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-900 text-blue-200">
                        {event.device}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        event.kind === 'error' ? 'bg-red-900 text-red-200' :
                        event.kind === 'warning' ? 'bg-yellow-900 text-yellow-200' :
                        event.kind === 'info' ? 'bg-green-900 text-green-200' :
                        'bg-slate-700 text-slate-300'
                      }`}>
                        {event.kind}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-300">
                      <div className="max-w-xs truncate">
                        {event.payload ? (
                          <pre className="text-xs bg-slate-900 p-2 rounded font-mono overflow-x-auto">
                            {JSON.stringify(event.payload, null, 2)}
                          </pre>
                        ) : (
                          <span className="text-slate-500 italic">No payload</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-900 text-green-200">
                        ● Live
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {allEvents.length > 0 && (
        <div className="flex justify-between items-center text-sm text-slate-400">
          <span>Showing {allEvents.length} events (most recent first)</span>
          <button 
            onClick={() => window.location.reload()} 
            className="px-3 py-1 bg-slate-700 hover:bg-slate-600 rounded text-xs transition-colors"
          >
            Clear & Refresh
          </button>
        </div>
      )}
    </main>
  )
}
