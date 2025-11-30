import azure.functions as func
import datetime
import json
import logging
import os
import requests

app = func.FunctionApp()

@app.function_name(name="reportmate_storage_alerts")
@app.schedule(schedule="0 22 11 * * *", arg_name="mytimer", run_on_startup=True, use_monitor=False)
def reportmate_storage_alerts(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()

    if mytimer.past_due:
        logging.info('The timer is past due!')

    logging.info('Python timer trigger function ran at %s', utc_timestamp)

    api_url = os.environ.get("REPORTMATE_API_URL")
    api_key = os.environ.get("REPORTMATE_API_KEY")
    webhook_url = os.environ.get("TEAMS_WEBHOOK_URL")

    if not api_url or not webhook_url:
        logging.error("Environment variables REPORTMATE_API_URL or TEAMS_WEBHOOK_URL are not set.")
        return

    headers = {}
    if api_key:
        headers["x-api-key"] = api_key
        headers["X-API-PASSPHRASE"] = api_key

    try:
        # 1. Get all devices
        devices_url = f"{api_url}/api/devices"
        logging.info(f"Fetching devices from {devices_url}")
        response = requests.get(devices_url, headers=headers)
        response.raise_for_status()
        devices_data = response.json()
        
        # Handle if the response is wrapped (e.g. {"devices": [...]}) or just a list
        devices = []
        if isinstance(devices_data, dict) and "devices" in devices_data:
            devices = devices_data["devices"]
        elif isinstance(devices_data, list):
            devices = devices_data
        
        logging.info(f"Processing {len(devices)} devices...")
        
        low_storage_devices = []

        for device in devices:
            serial_number = device.get("serial_number")
            if not serial_number:
                continue

            # Try to get hardware info from the device object (if bulk includes it)
            hardware = None
            device_name = device.get("device_name") or device.get("hostname") or serial_number

            if "modules" in device and "hardware" in device["modules"]:
                hardware = device["modules"]["hardware"]
            
            # If hardware info is missing in bulk, fetch individual device details
            if not hardware:
                try:
                    device_detail_url = f"{api_url}/api/device/{serial_number}"
                    dev_response = requests.get(device_detail_url, headers=headers)
                    if dev_response.status_code == 200:
                        dev_data = dev_response.json()
                        
                        # Update device name if we found better info
                        if "modules" in dev_data:
                            modules = dev_data["modules"]
                            if "inventory" in modules and "deviceName" in modules["inventory"]:
                                device_name = modules["inventory"]["deviceName"]
                            elif "system" in modules and "hostname" in modules["system"]:
                                device_name = modules["system"]["hostname"]
                                
                            if "hardware" in modules:
                                hardware = modules["hardware"]
                except Exception as e:
                    logging.error(f"Error fetching device details for {serial_number}: {e}")

            if hardware and "storage" in hardware and isinstance(hardware["storage"], list):
                for drive in hardware["storage"]:
                    # Check capacity and free space
                    try:
                        capacity = float(drive.get("capacity", 0))
                        free_space = float(drive.get("freeSpace", 0))
                        name = drive.get("name") or drive.get("id") or drive.get("device_id") or "Unknown Drive"
                        
                        # Filter out small partitions (e.g. recovery, boot) - say less than 10GB
                        if capacity > 10 * 1024**3: 
                            percent_free = (free_space / capacity) * 100
                            
                            if percent_free < 10:
                                low_storage_devices.append({
                                    "serial_number": serial_number,
                                    "device_name": device_name,
                                    "drive": name,
                                    "percent_free": round(percent_free, 2),
                                    "free_gb": round(free_space / (1024**3), 2),
                                    "total_gb": round(capacity / (1024**3), 2)
                                })
                    except (ValueError, TypeError):
                        continue

        if low_storage_devices:
            logging.info(f"Found {len(low_storage_devices)} devices with low storage.")
            send_teams_alert(webhook_url, low_storage_devices)
        else:
            logging.info("No devices with low storage found.")

    except Exception as e:
        logging.error(f"An error occurred: {e}")

def send_teams_alert(webhook_url, devices):
    # Limit the number of devices shown to avoid hitting Teams message size limits
    max_display = 10
    display_devices = devices[:max_display]
    remaining_count = len(devices) - max_display

    facts = []
    for d in display_devices:
        facts.append({
            "name": f"{d['device_name']}",
            "value": f"**{d['percent_free']}%** free ({d['free_gb']}GB / {d['total_gb']}GB) - Drive: {d['drive']}"
        })
    
    if remaining_count > 0:
        facts.append({
            "name": "...",
            "value": f"And {remaining_count} more devices."
        })

    message = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": "FF0000",
        "summary": "Low Storage Alert",
        "sections": [{
            "activityTitle": "⚠️ Low Storage Alert",
            "activitySubtitle": f"Found {len(devices)} devices with less than 10% free storage.",
            "facts": facts,
            "markdown": True
        }]
    }

    try:
        response = requests.post(webhook_url, json=message)
        response.raise_for_status()
        logging.info("Teams alert sent successfully.")
    except Exception as e:
        logging.error(f"Failed to send Teams alert: {e}")
