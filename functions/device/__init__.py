import json, logging
import azure.functions as func
from shared.db import get_pool
import uuid
from datetime import datetime

logging.basicConfig(level=logging.INFO)

# ----------------- config -----------------
POOL = get_pool()
# ------------------------------------------


def handle_device_registration(req: func.HttpRequest) -> func.HttpResponse:
    """
    Handle POST /api/device - Register a new device
    """
    try:
        # Get the device data from request body
        device_data = req.get_json()
        if not device_data:
            return func.HttpResponse(
                json.dumps({'error': 'Device data required'}),
                status_code=400,
                headers={'Content-Type': 'application/json'}
            )
        
        # Extract required fields
        device_id = device_data.get('id') or device_data.get('serialNumber')
        name = device_data.get('name') or device_data.get('hostname')
        
        if not device_id:
            return func.HttpResponse(
                json.dumps({'error': 'Device ID or serial number required'}),
                status_code=400,
                headers={'Content-Type': 'application/json'}
            )
        
        logging.info(f"Registering device: {device_id} ({name})")
        
        with POOL.connection() as conn:
            cur = conn.cursor()
            
            # Insert or update device
            cur.execute(
                """
                INSERT INTO devices (
                    id, name, model, os, serial_number, 
                    last_seen, status, created_at, updated_at
                ) VALUES (%s, %s, %s, %s, %s, NOW(), 'active', NOW(), NOW())
                ON CONFLICT (id) DO UPDATE SET
                    name = EXCLUDED.name,
                    model = EXCLUDED.model,
                    os = EXCLUDED.os,
                    serial_number = EXCLUDED.serial_number,
                    last_seen = NOW(),
                    status = 'active',
                    updated_at = NOW()
                """,
                (
                    device_id,
                    name,
                    device_data.get('model', 'Unknown'),
                    device_data.get('os', 'Unknown'),
                    device_data.get('serialNumber', device_id)
                )
            )
            
            # Create a "new_client" event for the device
            event_id = str(uuid.uuid4())
            cur.execute(
                """
                INSERT INTO events (id, device_id, kind, ts, payload, created_at)
                VALUES (%s, %s, 'new_client', NOW(), %s, NOW())
                ON CONFLICT (id) DO NOTHING
                """,
                (
                    event_id,
                    device_id,
                    json.dumps({
                        'message': 'Device registered successfully',
                        'source': 'device_registration',
                        'device_id': device_id,
                        'name': name,
                        'model': device_data.get('model', 'Unknown'),
                        'os': device_data.get('os', 'Unknown'),
                        'platform': device_data.get('platform', 'unknown'),
                        'registration_time': datetime.now().isoformat()
                    })
                )
            )
            
            conn.commit()
            
            logging.info(f"Device {device_id} registered successfully")
            return func.HttpResponse(
                json.dumps({
                    'success': True,
                    'message': 'Device registered successfully',
                    'device_id': device_id,
                    'event_id': event_id
                }),
                status_code=201,
                headers={'Content-Type': 'application/json'}
            )
            
    except Exception as e:
        logging.error(f"Error registering device: {str(e)}")
        return func.HttpResponse(
            json.dumps({
                'success': False,
                'error': str(e)
            }),
            status_code=500,
            headers={'Content-Type': 'application/json'}
        )


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    GET /api/device/{deviceId} - Returns detailed device information from the database
    POST /api/device - Register a new device
    """
    try:
        # Handle POST request for device registration
        if req.method == 'POST':
            return handle_device_registration(req)
        
        # Handle GET request for device information
        # Get device ID from route parameters
        device_id = req.route_params.get('deviceId')
        if not device_id:
            return func.HttpResponse(
                json.dumps({'error': 'Device ID required'}),
                status_code=400,
                headers={'Content-Type': 'application/json'}
            )
        
        # TEST: Check if tables exist
        try:
            with POOL.connection() as conn:
                cur = conn.cursor()
                
                # Test database connectivity and table existence
                cur.execute("SELECT COUNT(*) FROM devices")
                device_count = cur.fetchone()[0]
                
                cur.execute("SELECT COUNT(*) FROM events")  
                event_count = cur.fetchone()[0]
                
                return func.HttpResponse(
                    json.dumps({
                        'database_test': 'success',
                        'device_count': device_count,
                        'event_count': event_count,
                        'message': 'Database connection and tables working'
                    }),
                    status_code=200,
                    headers={'Content-Type': 'application/json'}
                )
        except Exception as e:
            return func.HttpResponse(
                json.dumps({
                    'database_test': 'failed',
                    'error': str(e),
                    'message': 'Database connectivity issue'
                }),
                status_code=500,
                headers={'Content-Type': 'application/json'}
            )
            
    except Exception as e:
        logging.error(f"Error fetching device {device_id}: {str(e)}")
        return func.HttpResponse(
            json.dumps({
                'success': False,
                'error': str(e)
            }),
            status_code=500,
            headers={'Content-Type': 'application/json'}
        )
