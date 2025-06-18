import json, os, azure.functions as func
from azure.messaging.webpubsubservice import WebPubSubServiceClient

WPS = WebPubSubServiceClient.from_connection_string(
    os.environ["EVENTS_CONNECTION"], hub="fleet"
)

def main(req: func.HttpRequest) -> func.HttpResponse:
    device = req.params.get("device", "anon")

    # correct call for SDK 1.2.2
    token_info = WPS.get_client_access_token(
        user_id=device,  # optional
        expires_in_minutes=60
    )
    # token_info is a dict: { "token": "...", "url": "wss://..." }

    return func.HttpResponse(
        json.dumps(token_info),
        mimetype="application/json"
    )
