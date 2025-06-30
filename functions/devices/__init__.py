import json, logging
import azure.functions as func
from shared.db import get_pool

logging.basicConfig(level=logging.INFO)

# ----------------- config -----------------
POOL = get_pool()
# ------------------------------------------


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    GET /api/devices - Returns devices from the database
    """
    try:
        with POOL.connection() as conn:
            cur = conn.cursor()
            
            # Get all devices with basic information
            cur.execute(
                """
                SELECT 
                    id, name, model, os, serial_number, asset_tag, 
                    ip_address, mac_address, location, last_seen, 
                    status, uptime, total_events, last_event_time,
                    processor, memory, storage, architecture,
                    disk_utilization, memory_utilization, cpu_utilization,
                    temperature, battery_level
                FROM devices 
                ORDER BY last_seen DESC NULLS LAST
                """
            )
            
            rows = cur.fetchall()
            
            # Convert to JSON-friendly format
            devices = []
            for row in rows:
                device = {
                    'id': row[0],
                    'name': row[1],
                    'model': row[2],
                    'os': row[3],
                    'serialNumber': row[4],
                    'assetTag': row[5],
                    'ipAddress': row[6],
                    'macAddress': row[7],
                    'location': row[8],
                    'lastSeen': row[9].isoformat() if row[9] else None,
                    'status': row[10],
                    'uptime': row[11],
                    'totalEvents': row[12] or 0,
                    'lastEventTime': row[13].isoformat() if row[13] else None,
                    'processor': row[14],
                    'memory': row[15],
                    'storage': row[16],
                    'architecture': row[17],
                    'diskUtilization': row[18],
                    'memoryUtilization': row[19],
                    'cpuUtilization': row[20],
                    'temperature': row[21],
                    'batteryLevel': row[22]
                }
                devices.append(device)
            
            return func.HttpResponse(
                json.dumps({
                    'success': True,
                    'devices': devices,
                    'count': len(devices)
                }),
                status_code=200,
                headers={'Content-Type': 'application/json'}
            )
            
    except Exception as e:
        logging.error(f"Error fetching devices: {str(e)}")
        return func.HttpResponse(
            json.dumps({
                'success': False,
                'error': str(e)
            }),
            status_code=500,
            headers={'Content-Type': 'application/json'}
        )
