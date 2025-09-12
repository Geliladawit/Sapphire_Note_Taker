import os
from google.cloud import secretmanager

def get_openai_api_key(project_id: str | None = None) -> str:
    client = secretmanager.SecretManagerServiceClient()
    project_id = project_id or os.environ.get("GCP_SECRET_ID")
    if not project_id:
        raise ValueError("GCP_SECRET_ID is not set and project_id was not provided")

    name = f"projects/{project_id}/secrets/OPENAI_API_KEY/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("utf-8")