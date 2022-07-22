import json
import os
from azure.storage.blob import BlobServiceClient

def get_configuration(config_container: str, config_file: str):
    """Loads a configuration file from a blob container in 'AzureWebJobsStorage'.

    Args:
        config_container (str): Blob container name.
        config_file (str): Configuration file name.

    Returns:
        Configuration file as JSON object.

    """

    service_client = BlobServiceClient.from_connection_string(os.environ['AzureWebJobsStorage'])
    config_data = service_client.get_blob_client(container=config_container, blob=config_file).download_blob().readall()
    
    return json.loads(config_data)