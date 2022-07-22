import azure.functions as func
from shared import notify

def main(mytimer: func.TimerRequest) -> None:

    # Set timer trigger cron in function.json
    # Define source ids to be notified by the trigger:
    source_ids = ["example_source/example_entity_1", "example_source/example_entity_2"]

    notify.notify(source_ids)
    return