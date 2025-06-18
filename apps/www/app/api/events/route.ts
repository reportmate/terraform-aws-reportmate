import { NextResponse } from 'next/server'

// Simple in-memory storage for recent events (in production, use Redis or database)
let recentEvents: any[] = []

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
