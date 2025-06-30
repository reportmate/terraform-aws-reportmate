import json, logging
import azure.functions as func
from shared.db import get_pool

logging.basicConfig(level=logging.INFO)

# ----------------- config -----------------
POOL = get_pool()
# ------------------------------------------


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    GET /api/device/{deviceId} - Returns detailed device information from the database
    """
    try:
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
