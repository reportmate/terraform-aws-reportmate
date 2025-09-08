import json, logging
import azure.functions as func
from shared.db import get_pool

logging.basicConfig(level=logging.INFO)

# ----------------- config -----------------
POOL = get_pool()
# ------------------------------------------


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    GET /api/events - Returns recent events from the database
    POST /api/events - Accept Windows client event data (temporarily just log it)
    """
    
    if req.method == "POST":
        return handle_post_events(req)
    else:
        return handle_get_events(req)


def handle_post_events(req: func.HttpRequest) -> func.HttpResponse:
    """Handle POST requests from Windows client - temporary implementation"""
    try:
        # Parse Windows client format
        body = req.get_json()
        logging.info(f"Received POST to /api/events with payload size: {len(json.dumps(body)) if body else 0} bytes")
        
        # For now, just log and return success
        # TODO: Queue the data for processing once queue is configured
        if body:
            device = body.get('Device', 'unknown')
            kind = body.get('Kind', 'unknown')
            logging.info(f"Windows client data received - Device: {device}, Kind: {kind}")
        
        # Return success for now
        return func.HttpResponse(
            json.dumps({"status": "accepted", "message": "Data received and logged"}),
            status_code=202,
            headers={'Content-Type': 'application/json'}
        )
            
    except Exception as e:
        logging.error(f"Error processing POST to /api/events: {str(e)}")
        return func.HttpResponse(
            f"Internal server error: {str(e)}", status_code=500
        )


def handle_get_events(req: func.HttpRequest) -> func.HttpResponse:
    """Handle GET requests for retrieving events"""
    try:
        limit = int(req.params.get('limit', '50'))
        device_id = req.params.get('device')
        
        with POOL.connection() as conn:
            cur = conn.cursor()
            
            # Build query based on parameters
            if device_id:
                # Get events for specific device
                cur.execute(
                    """
                    SELECT id, device_id as device, kind, ts, payload 
                    FROM events 
                    WHERE device_id = %s 
                    ORDER BY ts DESC 
                    LIMIT %s
                    """,
                    (device_id, limit)
                )
            else:
                # Get recent events for all devices
                cur.execute(
                    """
                    SELECT id, device_id as device, kind, ts, payload 
                    FROM events 
                    ORDER BY ts DESC 
                    LIMIT %s
                    """,
                    (limit,)
                )
            
            rows = cur.fetchall()
            
            # Convert to JSON-friendly format
            events = []
            for row in rows:
                events.append({
                    'id': row[0],
                    'device': row[1],
                    'kind': row[2],
                    'ts': row[3].isoformat(),
                    'payload': row[4] if isinstance(row[4], dict) else json.loads(row[4])
                })
            
            return func.HttpResponse(
                json.dumps({
                    'success': True,
                    'events': events,
                    'count': len(events)
                }),
                status_code=200,
                headers={'Content-Type': 'application/json'}
            )
            
    except Exception as e:
        logging.error(f"Error fetching events: {str(e)}")
        return func.HttpResponse(
            json.dumps({
                'success': False,
                'error': str(e)
            }),
            status_code=500,
            headers={'Content-Type': 'application/json'}
        )
