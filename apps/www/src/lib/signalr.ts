"use client"

import { useEffect, useState } from "react"
import { HubConnectionBuilder, HubConnection, LogLevel } from "@microsoft/signalr"

export interface FleetEvent {
  id: string
  device: string
  kind: string
  ts: string
  payload: Record<string, unknown>
}

async function refreshToken(): Promise<string> {
  try {
    console.log("🔄 Fetching negotiate token...")
    const response = await fetch("https://seemianki-api.azurewebsites.net/api/negotiate?device=dashboard-web")
    if (!response.ok) {
      throw new Error(`Negotiate API returned ${response.status}: ${response.statusText}`)
    }
    const data = await response.json()
    console.log("✅ Token refreshed successfully")
    return data.token
  } catch (error) {
    console.error("❌ Failed to refresh token:", error)
    throw new Error(`Token refresh failed: ${(error as Error).message}`)
  }
}

async function fetchRecentEvents(): Promise<FleetEvent[]> {
  try {
    const response = await fetch('/api/events')
    if (!response.ok) {
      throw new Error(`Events API returned ${response.status}`)
    }
    const data = await response.json()
    return data.events || []
  } catch (error) {
    console.error("❌ Failed to fetch recent events:", error)
    return []
  }
}

// Add a flag to control SignalR connection attempts
const ENABLE_SIGNALR = process.env.NODE_ENV === 'production' || process.env.NEXT_PUBLIC_ENABLE_SIGNALR === 'true'

export function useLiveEvents() {
  const [events, setEvents] = useState<FleetEvent[]>([])
  const [connectionStatus, setConnectionStatus] = useState<string>("connecting")

  useEffect(() => {
    let connection: HubConnection | null = null
    
    // Add initial test event to show UI is working
    const testEvent: FleetEvent = {
      id: "test-" + Date.now(),
      device: "dashboard-client",
      kind: "system",
      ts: new Date().toISOString(),
      payload: { 
        message: "Dashboard loaded successfully", 
        status: "ready",
        signalr: ENABLE_SIGNALR ? "enabled" : "disabled (dev mode)"
      }
    }
    setEvents([testEvent])
    console.log("✅ Dashboard initialized with test event")
    
    if (!ENABLE_SIGNALR) {
      setConnectionStatus("disabled")
      console.log("🔧 SignalR disabled in development mode. Set NEXT_PUBLIC_ENABLE_SIGNALR=true to enable.")
      return
    }
    
    async function startConnection() {
      try {
        setConnectionStatus("connecting")
        
        // Get a fresh token from the negotiate endpoint
        console.log("🔄 Getting fresh token from negotiate endpoint...")
        const token = await refreshToken()
        const url = "wss://seemianki-signalr.webpubsub.azure.com/client/hubs/fleet"
        
        console.log("🚀 Starting SignalR connection to:", url)
        
        connection = new HubConnectionBuilder()
          .withUrl(url, {
            accessTokenFactory: () => token
          })
          .configureLogging(LogLevel.Information)
          .withAutomaticReconnect()
          .build()

        // Handle incoming messages from Azure Web PubSub
        // Azure Web PubSub can send messages in different ways, so we'll listen for multiple event types
        
        // Listen for direct JSON messages (most common with send_to_all)
        connection.on("message", (message: any) => {
          console.log("📨 Received 'message' event:", message)
          handleIncomingMessage(message)
        })
        
        // Listen for server messages (alternative event type)
        connection.on("server", (message: any) => {
          console.log("📨 Received 'server' event:", message)
          handleIncomingMessage(message)
        })
        
        // Listen for any custom events that might be sent
        connection.on("broadcastMessage", (message: any) => {
          console.log("📨 Received 'broadcastMessage' event:", message)
          handleIncomingMessage(message)
        })
        
        // Generic message handler
        function handleIncomingMessage(message: any) {
          try {
            console.log("🔄 Processing message:", typeof message, message)
            let messageData = message
            
            // If it's a string, try to parse it as JSON
            if (typeof message === 'string') {
              messageData = JSON.parse(message)
            }
            
            // Ensure we have an array of events
            const eventsArray = Array.isArray(messageData) ? messageData : [messageData]
            console.log("📊 Adding events to state:", eventsArray)
            
            setEvents(prev => {
              // Avoid duplicates by checking IDs
              const existingIds = new Set(prev.map(e => e.id))
              const newEvents = eventsArray.filter((e: any) => e.id && !existingIds.has(e.id))
              return [...prev, ...newEvents]
            })
          } catch (error) {
            console.error("❌ Error processing message:", error, message)
          }
        }
        
        // Handle connection status changes
        connection.onclose((error) => {
          console.log("🔌 SignalR connection closed", error)
          setConnectionStatus("disconnected")
        })
        
        connection.onreconnecting((error) => {
          console.log("🔄 SignalR reconnecting...", error)
          setConnectionStatus("reconnecting")
        })
        
        connection.onreconnected((connectionId) => {
          console.log("✅ SignalR reconnected", connectionId)
          setConnectionStatus("connected")
        })

        await connection.start()
        console.log("✅ SignalR connection established")
        setConnectionStatus("connected")
        
      } catch (error) {
        const errorMessage = (error as Error).message
        console.error("❌ Failed to start SignalR connection:", error)
        setConnectionStatus("error")
        
        // Add error event to show what happened with more specific error details
        const errorEvent: FleetEvent = {
          id: "error-" + Date.now(),
          device: "dashboard-client",
          kind: "error",
          ts: new Date().toISOString(),
          payload: { 
            error: errorMessage.includes('Load failed') ? 'WebSocket connection blocked by browser (CORS/network issue)' : errorMessage,
            type: "signalr_connection_failed",
            details: errorMessage,
            note: "This is expected in development - SignalR events won't work until Azure Web PubSub CORS is configured"
          }
        }
        setEvents(prev => [errorEvent, ...prev])
      }
    }

    startConnection()

    // Always set up polling as fallback for API events
    const pollEvents = async () => {
      try {
        const apiEvents = await fetchRecentEvents()
        if (apiEvents.length > 0) {
          console.log(`📊 Fetched ${apiEvents.length} events from API`)
          setEvents(prev => {
            // Merge API events with existing events, avoid duplicates
            const existingIds = new Set(prev.map(e => e.id))
            const newEvents = apiEvents.filter(e => !existingIds.has(e.id))
            return newEvents.length > 0 ? [...newEvents, ...prev] : prev
          })
        }
      } catch (error) {
        console.error("❌ Polling failed:", error)
      }
    }

    // Poll every 5 seconds for new events
    const pollInterval = setInterval(pollEvents, 5000)
    
    // Initial fetch
    pollEvents()

    if (!ENABLE_SIGNALR) {
      setConnectionStatus("polling")
      console.log("🔧 SignalR disabled, using polling mode for events")
      return () => clearInterval(pollInterval)
    }
    
    return () => {
      if (connection) {
        console.log("🧹 Cleaning up SignalR connection")
        connection.stop()
      }
      clearInterval(pollInterval)
    }
  }, [])

  return { 
    events, 
    connectionStatus,
    addEvent: (event: FleetEvent) => setEvents(prev => [event, ...prev])
  }
}
