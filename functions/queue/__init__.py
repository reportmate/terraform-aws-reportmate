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


def main(msg: func.QueueMessage):
    raw: str = msg.get_body().decode()
    row = json.loads(raw)

    with POOL.connection() as conn:
        cur = conn.cursor()
        if row["kind"] == "cimian_run":
            _handle_cimian_run(row, cur)
        else:
            # generic fallback into events table
            cur.execute(
                """
                insert into events(id, device, kind, ts, payload)
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