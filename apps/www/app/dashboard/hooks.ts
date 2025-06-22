"use client"

import { useEffect, useState, useCallback } from "react"
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
  const [lastUpdateTime, setLastUpdateTime] = useState<Date | null>(null)
  const [mounted, setMounted] = useState(false)

  // Ensure we're mounted before showing time-dependent data
  useEffect(() => {
    setMounted(true)
    setLastUpdateTime(new Date())
  }, [])

  // Function to fetch events from local API
  const fetchLocalEvents = useCallback(async () => {
    try {
      const response = await fetch('/api/events')
      if (response.ok) {
        const data = await response.json()
        if (data.success && data.events) {
          setEvents(prev => {
            // Merge new events, avoiding duplicates
            const existingIds = new Set(prev.map(e => e.id))
            const newEvents = data.events.filter((e: FleetEvent) => !existingIds.has(e.id))
            if (newEvents.length > 0) {
              setLastUpdateTime(new Date())
              return [...prev, ...newEvents].slice(-100) // Keep only last 100 events
            }
            return prev
          })
        }
      }
    } catch (error) {
      console.error("Failed to fetch local events:", error)
    }
  }, [])

  useEffect(() => {
    let connection: HubConnection | null = null
    let pollingInterval: NodeJS.Timeout | null = null
    
    // Add initial test event to show UI is working
    const testEvent: FleetEvent = {
      id: "test-" + Date.now(),
      device: "dashboard-client",
      kind: "system",
      ts: new Date().toISOString(),
      payload: { message: "Dashboard loaded successfully", status: "ready" }
    }
    setEvents([testEvent])
    setLastUpdateTime(new Date())
    console.log("Dashboard initialized with test event")
    
    async function startConnection() {
      try {
        setConnectionStatus("connecting")
        
        // Get a fresh token from the negotiate endpoint
        console.log("Getting fresh token from negotiate endpoint...")
        const response = await fetch("https://seemianki-api.azurewebsites.net/api/negotiate?device=dashboard-web")
        if (!response.ok) {
          throw new Error(`Negotiate failed: ${response.status}`)
        }
        
        const tokenData = await response.json()
        console.log("Got negotiate response:", { baseUrl: tokenData.baseUrl, hasToken: !!tokenData.token })
        
        const url = tokenData.baseUrl || "wss://seemianki-signalr.webpubsub.azure.com/client/hubs/fleet"
        
        console.log("Starting SignalR connection to:", url)
        
        connection = new HubConnectionBuilder()
          .withUrl(url, {
            accessTokenFactory: () => tokenData.token
          })
          .configureLogging(LogLevel.Information)
          .withAutomaticReconnect([0, 2000, 10000, 30000])
          .build()

        // Handle incoming messages from multiple event types
        const handleIncomingMessage = (message: any) => {
          try {
            console.log("Processing message:", typeof message, message)
            let messageData = message
            
            if (typeof message === 'string') {
              messageData = JSON.parse(message)
            }
            
            const eventsArray = Array.isArray(messageData) ? messageData : [messageData]
            console.log("Adding events to state:", eventsArray)
            
            setEvents(prev => {
              const existingIds = new Set(prev.map(e => e.id))
              const newEvents = eventsArray.filter((e: any) => e.id && !existingIds.has(e.id))
              if (newEvents.length > 0) {
                setLastUpdateTime(new Date())
                return [...prev, ...newEvents].slice(-100)
              }
              return prev
            })
          } catch (error) {
            console.error("Error processing message:", error, message)
          }
        }

        // Listen for multiple message types
        connection.on("broadcastMessage", handleIncomingMessage)
        connection.on("message", handleIncomingMessage)
        connection.on("server", handleIncomingMessage)
        
        // Handle connection status changes
        connection.onclose((error) => {
          console.log("SignalR connection closed", error)
          setConnectionStatus("disconnected")
          // Start polling when SignalR is down
          startPolling()
        })
        
        connection.onreconnecting((error) => {
          console.log("SignalR reconnecting...", error)
          setConnectionStatus("reconnecting")
          if (pollingInterval) {
            clearInterval(pollingInterval)
            pollingInterval = null
          }
        })
        
        connection.onreconnected((connectionId) => {
          console.log("SignalR reconnected", connectionId)
          setConnectionStatus("connected")
          if (pollingInterval) {
            clearInterval(pollingInterval)
            pollingInterval = null
          }
        })

        await connection.start()
        console.log("SignalR connection established")
        setConnectionStatus("connected")
        
      } catch (error) {
        console.error("Failed to start SignalR connection:", error)
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
        setLastUpdateTime(new Date())
        
        // Start polling as fallback
        startPolling()
      }
    }

    function startPolling() {
      if (pollingInterval) return // Already polling
      
      setConnectionStatus("polling")
      console.log("Starting polling fallback")
      
      // Fetch events immediately
      fetchLocalEvents()
      
      // Poll every 5 seconds
      pollingInterval = setInterval(fetchLocalEvents, 5000)
    }

    startConnection()

    return () => {
      if (connection) {
        console.log("Cleaning up SignalR connection")
        connection.stop()
      }
      if (pollingInterval) {
        clearInterval(pollingInterval)
      }
    }
  }, [fetchLocalEvents])

  return { 
    events, 
    connectionStatus,
    lastUpdateTime,
    mounted,
    addEvent: (event: FleetEvent) => {
      setEvents(prev => [event, ...prev].slice(-100))
      setLastUpdateTime(new Date())
    }
  }
}
