import logging
import os
import azure.functions as func
from shared import get_configuration
from adenotifier import notifier

def identify_sources(file_url: str, config: object):
    """Compares a file url to the data source configuration to find matches.

    Args:
        file_url (str): File url (from Microsoft.Storage.BlobCreated event).
        config_file (object): Data source configuration file as JSON object.

    Returns:
        List of matched sources.

    """

    sources = []
    
    for source in config:
        source_storage = source['attributes']['storage_account']
        source_path = "{0}/{1}".format(source['attributes']['storage_container'], source['attributes']['folder_path'])
        
        # Optional attribute
        if ('file_extension' in source['attributes']):
            source_extension = source['attributes']['file_extension']
        else:
            source_extension = ""

        if (source_storage in file_url and source_path in file_url and source_extension in file_url):
            sources.append(source)

    return sources

def main(msg: func.QueueMessage) -> None:
    """Triggered when a message is received to the notifier-trigger queue.
    Gets configuration, identifies data source, adds file to a manifest if source is identified.
        
    Args:
        msg (Azure.Functions.QueueMessage): Queue message (Microsoft.Storage.BlobCreated event) which triggers the function.

    Returns:
        None.

    """

    logging.info('Python queue trigger function processed a queue item:\n{0}'.format(msg.get_body().decode('utf-8')))
    msg_json = msg.get_json()
    event_url = msg_json['data']['url']

    # Get configuration file (AzureWebJobsStorage/datasource-config/datasources.json)
    config = get_configuration.get_configuration(config_container = "datasource-config", config_file = "datasources.json")

    # Identify data sources
    sources = identify_sources(event_url, config)
    if (sources == []):
        logging.info('Source not identified for url: {0}'.format(event_url))
        return            

    # Manifests
    for source in sources:
        logging.info('Processing source: {0}'.format(source['id']))
        notifier.add_to_manifest(event_url, source, os.environ['notify_api_base_url'], os.environ['notify_api_key'], os.environ['notify_api_key_secret'])

    return