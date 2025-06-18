import { NextRequest, NextResponse } from 'next/server'

export async function GET() {
  try {
    // Get negotiate info to test Azure connection
    const negotiateResponse = await fetch('https://seemianki-api.azurewebsites.net/api/negotiate?device=api-test')
    const negotiateData = await negotiateResponse.json()
    
    return NextResponse.json({
      success: true,
      timestamp: new Date().toISOString(),
      negotiate: negotiateData,
      message: "API endpoint working"
    })
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: (error as Error).message,
      timestamp: new Date().toISOString()
    }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    // Store the event locally for dashboard display
    const localStoreResponse = await fetch(`${request.nextUrl.origin}/api/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    })
    
    // Forward to Azure Function
    const response = await fetch('https://seemianki-api.azurewebsites.net/api/ingest', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body)
    })
    
    if (response.ok) {
      return NextResponse.json({ 
        success: true, 
        message: "Event sent successfully",
        storedLocally: localStoreResponse.ok
      })
    } else {
      return NextResponse.json({ 
        success: false, 
        error: `Azure function returned ${response.status}` 
      }, { status: response.status })
    }
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: (error as Error).message
    }, { status: 500 })
  }
}
