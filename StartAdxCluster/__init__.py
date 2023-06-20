import datetime
import logging
import os
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.kusto import KustoManagementClient


def main(startadxtimer: func.TimerRequest) -> None:

    SUBSCRIPTION_ID = os.environ["AZURE_SUBSCRIPTION_ID"]
    ADX_RESOURCE_GROUP = os.environ["ADX_RESOURCE_GROUP"]
    ADX_CLUSTER_NAME = os.environ["ADX_CLUSTER_NAME"]

    client = KustoManagementClient(credential=DefaultAzureCredential(), subscription_id=SUBSCRIPTION_ID)

    utc_timestamp = datetime.datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc).isoformat()
    
    poller = client.clusters.begin_start(
        resource_group_name=ADX_RESOURCE_GROUP,
        cluster_name=ADX_CLUSTER_NAME,
    )
    if poller.done():
        logging.info(f"Started Kusto Cluster {ADX_CLUSTER_NAME}: {ADX_RESOURCE_GROUP}...")

    logging.info(f"Python timer trigger function ran {utc_timestamp}")
