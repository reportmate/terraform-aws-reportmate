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
      payload: { message: "Dashboard loaded successfully", status: "ready" }
    }
    setEvents([testEvent])
    console.log("✅ Dashboard initialized with test event")
    
    async function startConnection() {
      try {
        setConnectionStatus("connecting")
        
        // Get a fresh token from the negotiate endpoint
        console.log("🔄 Getting fresh token from negotiate endpoint...")
        const response = await fetch("https://seemianki-api.azurewebsites.net/api/negotiate?device=dashboard-web")
        if (!response.ok) {
          throw new Error(`Negotiate failed: ${response.status}`)
        }
        
        const tokenData = await response.json()
        console.log("📝 Got negotiate response:", { baseUrl: tokenData.baseUrl, hasToken: !!tokenData.token })
        
        const url = tokenData.baseUrl || "wss://seemianki-signalr.webpubsub.azure.com/client/hubs/fleet"
        
        console.log("🚀 Starting SignalR connection to:", url)
        
        connection = new HubConnectionBuilder()
          .withUrl(url, {
            accessTokenFactory: () => tokenData.token
          })
          .configureLogging(LogLevel.Information)
          .withAutomaticReconnect()
          .build()

        // Handle incoming messages  
        connection.on("broadcastMessage", (message: string) => {
          console.log("📨 Received broadcast message:", message)
          try {
            const fleetEvents = JSON.parse(message)
            const eventsArray = Array.isArray(fleetEvents) ? fleetEvents : [fleetEvents]
            console.log("📊 Adding events to state:", eventsArray)
            setEvents(prev => [...prev, ...eventsArray])
          } catch (error) {
            console.error("❌ Error parsing broadcast message:", error)
          }
        })
        
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
        console.error("❌ Failed to start SignalR connection:", error)
        setConnectionStatus("error")
        
        // Add error event to show what happened
        const errorEvent: FleetEvent = {
          id: "error-" + Date.now(),
          device: "dashboard-client",
          kind: "error",
          ts: new Date().toISOString(),
          payload: { error: (error as Error).message, type: "connection_failed" }
        }
        setEvents(prev => [errorEvent, ...prev])
      }
    }

    startConnection()

    return () => {
      if (connection) {
        console.log("🧹 Cleaning up SignalR connection")
        connection.stop()
      }
    }
  }, [])

  return { 
    events, 
    connectionStatus,
    addEvent: (event: FleetEvent) => setEvents(prev => [event, ...prev])
  }
}
