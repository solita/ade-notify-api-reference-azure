import logging
import os
from typing import List
from shared import get_configuration
from adenotifier import notifier

def notify(source_ids: List[str]) -> None:
    """Notifies open manifests for given source ids.

    Args:
        source_ids (List[str]): List of source ids in the same format as in the data source configuration file.

    Returns:
        None.

    """

    # Get configuration file (AzureWebJobsStorage/datasource-config/datasources.json)
    config = get_configuration.get_configuration(config_container = "datasource-config", config_file = "datasources.json")
        
    for source_id in source_ids:
        for source in config:
            if source['id'] == source_id:
                logging.info('Notifying source: {0}'.format(source['id']))
                notifier.notify_manifests(source, os.environ['notify_api_base_url'], os.environ['notify_api_key'], os.environ['notify_api_key_secret'])
                break    
    return