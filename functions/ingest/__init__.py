import json, os, uuid, datetime
import azure.functions as func
from azure.storage.queue import QueueClient
from pydantic import BaseModel, Field, ValidationError


# ----------------- config -----------------
QUEUE_NAME   = os.environ["QUEUE_NAME"]
QUEUE_CLIENT = QueueClient.from_connection_string(
    conn_str=os.environ["AZURE_STORAGE_CONNECTION_STRING"],
    queue_name=QUEUE_NAME,
)
# ------------------------------------------


class Payload(BaseModel):
    device: str
    kind: str
    ts: datetime.datetime | None = None
    payload: dict = Field(default_factory=dict)


def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        body = req.get_json()
        model = Payload.model_validate(body)
    except (ValueError, ValidationError) as exc:
        return func.HttpResponse(
            "invalid JSON: " + str(exc), status_code=400
        )

    # fill missing fields
    data = model.model_dump()
    data["id"] = str(uuid.uuid4())
    if data["ts"] is None:
        data["ts"] = datetime.datetime.utcnow().isoformat()

    # enqueue
    QUEUE_CLIENT.send_message(json.dumps(data))

    return func.HttpResponse(status_code=202)