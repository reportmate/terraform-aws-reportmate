import { NextResponse } from 'next/server'

// Simple in-memory storage for recent events (in production, use Redis or database)
let recentEvents: Array<Record<string, unknown>> = [
  {
    id: 'demo-1',
    device: 'server-01',
    kind: 'success',
    ts: new Date(Date.now() - 60000).toISOString(),
    payload: { message: 'System startup completed successfully', status: 'healthy' }
  },
  {
    id: 'demo-2', 
    device: 'workstation-A',
    kind: 'warning',
    ts: new Date(Date.now() - 120000).toISOString(),
    payload: { message: 'Disk space running low (15% remaining)', threshold: '85%' }
  },
  {
    id: 'demo-3',
    device: 'laptop-001',
    kind: 'error',
    ts: new Date(Date.now() - 180000).toISOString(),
    payload: { message: 'Authentication service unreachable', service: 'auth-api' }
  },
  {
    id: 'demo-4',
    device: 'vehicle-08',
    kind: 'info',
    ts: new Date(Date.now() - 240000).toISOString(),
    payload: { message: 'GPS location updated', lat: 37.7749, lng: -122.4194 }
  }
]

export async function GET() {
  try {
    // Return the most recent 50 events
    const events = recentEvents
      .slice(-50)
      .reverse() // Most recent first
      .map(event => ({
        id: event.id || `event-${Date.now()}-${Math.random()}`,
        device: event.device || 'unknown',
        kind: event.kind || 'unknown',
        ts: event.ts || new Date().toISOString(),
        payload: event.payload || {}
      }))

    return NextResponse.json({
      success: true,
      events,
      count: events.length
    })
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: (error as Error).message
    }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const event = await request.json()
    
    // Add ID if not present
    if (!event.id) {
      event.id = `event-${Date.now()}-${Math.random()}`
    }
    
    // Add timestamp if not present
    if (!event.ts) {
      event.ts = new Date().toISOString()
    }
    
    // Add to recent events
    recentEvents.push(event)
    
    // Keep only last 100 events in memory
    if (recentEvents.length > 100) {
      recentEvents = recentEvents.slice(-100)
    }
    
    return NextResponse.json({
      success: true,
      message: "Event stored",
      eventId: event.id
    })
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: (error as Error).message
    }, { status: 500 })
  }
}
