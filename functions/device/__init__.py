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
        
        with POOL.connection() as conn:
            cur = conn.cursor()
            
            # Get device information
            cur.execute(
                """
                SELECT 
                    id, name, model, os, serial_number, asset_tag, 
                    ip_address, mac_address, location, last_seen, 
                    status, uptime, total_events, last_event_time,
                    processor, memory, storage, architecture,
                    disk_utilization, memory_utilization, cpu_utilization,
                    temperature, battery_level, boot_time
                FROM devices 
                WHERE id = %s
                """,
                (device_id,)
            )
            
            device_row = cur.fetchone()
            if not device_row:
                return func.HttpResponse(
                    json.dumps({'error': 'Device not found'}),
                    status_code=404,
                    headers={'Content-Type': 'application/json'}
                )
            
            # Get recent events for this device
            cur.execute(
                """
                SELECT id, kind, ts, payload 
                FROM events 
                WHERE device_id = %s 
                ORDER BY ts DESC 
                LIMIT 20
                """,
                (device_id,)
            )
            
            event_rows = cur.fetchall()
            
            # Build device info response
            device_info = {
                'id': device_row[0],
                'name': device_row[1],
                'model': device_row[2],
                'os': device_row[3],
                'serialNumber': device_row[4],
                'assetTag': device_row[5],
                'ipAddress': device_row[6],
                'macAddress': device_row[7],
                'location': device_row[8],
                'lastSeen': device_row[9].isoformat() if device_row[9] else None,
                'status': device_row[10],
                'uptime': device_row[11],
                'totalEvents': device_row[12] or 0,
                'lastEventTime': device_row[13].isoformat() if device_row[13] else None,
                'processor': device_row[14],
                'memory': device_row[15],
                'storage': device_row[16],
                'architecture': device_row[17],
                'diskUtilization': device_row[18],
                'memoryUtilization': device_row[19],
                'cpuUtilization': device_row[20],
                'temperature': device_row[21],
                'batteryLevel': device_row[22],
                'bootTime': device_row[23].isoformat() if device_row[23] else None
            }
            
            # Build events response
            events = []
            for row in event_rows:
                events.append({
                    'id': row[0],
                    'device': device_id,
                    'kind': row[1],
                    'ts': row[2].isoformat(),
                    'payload': row[3] if isinstance(row[3], dict) else json.loads(row[3])
                })
            
            return func.HttpResponse(
                json.dumps({
                    'deviceInfo': device_info,
                    'events': events
                }),
                status_code=200,
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
