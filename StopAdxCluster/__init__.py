import datetime
import logging
import os
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.kusto import KustoManagementClient
import holidays


def main(stopadxtimer: func.TimerRequest) -> None:

    SUBSCRIPTION_ID = os.environ["AZURE_SUBSCRIPTION_ID"]
    ADX_CLUSTERS_CONFIG = json.loads(os.environ["ADX_CLUSTERS_CONFIG"])
    # ADX_CLUSTERS_CONFIG=[{"cluster_name": "cluster1", "resource_group": "group1"}, {"cluster_name": "cluster2", "resource_group": "group2"}, ...]
    COUNTRY = os.environ.get("HOLIDAY_COUNTRY", "FR")  # Default to FR

    client = KustoManagementClient(credential=DefaultAzureCredential(), subscription_id=SUBSCRIPTION_ID)
    
    utc_timestamp = datetime.datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc).isoformat()
    
    # Check if public holiday
    country_holidays = holidays.country_holidays(COUNTRY)
    if utc_timestamp.date() in country_holidays:
        logging.info(f"Today ({utc_timestamp.date()}) is a holiday. Skipping cluster stop.")
        return

    for cluster_config in ADX_CLUSTERS_CONFIG:
        resource_group = cluster_config['resource_group']
        cluster_name = cluster_config['cluster_name']
        
        poller = client.clusters.begin_stop(
            resource_group_name=resource_group,
            cluster_name=cluster_name,
        )
        if poller.done():
            logging.info(f"Stopped Kusto Cluster {cluster_name} in {resource_group}...")

    logging.info(f"Python timer trigger function ran at {utc_timestamp}")
