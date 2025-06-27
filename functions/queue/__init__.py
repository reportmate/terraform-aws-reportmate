import json, os, psycopg, logging
import azure.functions as func
from azure.messaging.webpubsubservice import WebPubSubServiceClient
from shared.db import get_pool

logging.basicConfig(level=logging.INFO)

# ----------------- config -----------------
POOL              = get_pool()
WPS_CLIENT        = WebPubSubServiceClient.from_connection_string(
    os.environ["EVENTS_CONNECTION"], hub="fleet"
)
# ------------------------------------------


def _handle_cimian_run(row: dict, cur):
    payload = row["payload"]
    cur.execute(
        """
        insert into cimian_runs(id, device, ts, exit_code, duration, details)
        values (%s,%s,%s,%s,%s,%s)
        on conflict do nothing
        """,
        (
            row["id"],
            row["device"],
            row["ts"],
            payload.get("exitCode"),
            payload.get("duration"),
            payload.get("details"),
        ),
    )


def _ensure_device_exists(device_id: str, passphrase_hash: str | None, cur):
    """
    Ensure device exists in database and assign to machine group if passphrase provided.
    Similar to MunkiReport's _register function.
    """
    machine_group_id = None
    
    # If passphrase hash is provided, find matching machine group
    if passphrase_hash:
        cur.execute(
            "SELECT id FROM machine_groups WHERE passphrase_hash = %s LIMIT 1",
            (passphrase_hash,)
        )
        result = cur.fetchone()
        if result:
            machine_group_id = result[0]
            logging.info(f"Device {device_id} assigned to machine group {machine_group_id}")
        else:
            logging.warning(f"No machine group found for passphrase hash: {passphrase_hash[:8]}...")
    
    # Upsert device with machine group assignment
    cur.execute(
        """
        INSERT INTO devices (id, name, machine_group_id, last_seen, status, created_at, updated_at)
        VALUES (%s, %s, %s, NOW(), 'active', NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET
            machine_group_id = COALESCE(EXCLUDED.machine_group_id, devices.machine_group_id),
            last_seen = NOW(),
            status = 'active',
            updated_at = NOW()
        """,
        (device_id, device_id, machine_group_id)
    )


def main(msg: func.QueueMessage):
    raw: str = msg.get_body().decode()
    row = json.loads(raw)

    with POOL.connection() as conn:
        cur = conn.cursor()
        
        # Ensure device exists and assign to machine group if applicable
        passphrase_hash = row.get("passphrase_hash")
        _ensure_device_exists(row["device"], passphrase_hash, cur)
        
        if row["kind"] == "cimian_run":
            _handle_cimian_run(row, cur)
        else:
            # generic fallback into events table
            cur.execute(
                """
                insert into events(id, device_id, kind, ts, payload)
                values (%s,%s,%s,%s,%s::jsonb)
                on conflict do nothing
                """,
                (
                    row["id"],
                    row["device"],
                    row["kind"],
                    row["ts"],
                    json.dumps(row["payload"]),
                ),
            )

    # broadcast to dashboards
    WPS_CLIENT.send_to_all(json.dumps([row]), content_type="application/json")