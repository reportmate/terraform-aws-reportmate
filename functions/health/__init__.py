import json
import azure.functions as func
import logging
from datetime import datetime

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Simple health check endpoint for Azure Front Door
    """
    try:
        return func.HttpResponse(
            json.dumps({
                'status': 'healthy',
                'timestamp': datetime.utcnow().isoformat(),
                'service': 'reportmate-api'
            }),
            status_code=200,
            headers={'Content-Type': 'application/json'}
        )
    except Exception as e:
        logging.error(f"Health check failed: {str(e)}")
        return func.HttpResponse(
            json.dumps({
                'status': 'unhealthy',
                'error': str(e)
            }),
            status_code=500,
            headers={'Content-Type': 'application/json'}
        )
