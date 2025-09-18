# Azure Functions Timer Trigger 

This repository contains source code of azure functions for auto stop/start AKS and ADX services.

## Terraform deployment
```
git clone git@github.com:Cosmo-Tech/azure-function-app-stop-start.git
cd azure-function-app-stop-start/terraform
```

```
terraform init
terraform plan -out tfplan
```

```
terraform apply tfplan
```

## Manual deployment
### 1. Prerequisite

Create an app registration that will be the Azure identity used to trigger the Stop/Start:
* Name: `Cosmo Tech CRON For <platform_name>`
* `Contributor` role assigned on the platform resource group (containing AKS and ADX)
* Create a secret

### 2. Azure Function App deployment and configuration

Individual functions in a function app are deployed together and are scaled together. 
All functions in the same function app share resources, per instance, as the function app scales.

* Clone current repository
* Based on VSCode Azure Extension, create a Function App in Azure
    * Naming convention: `azf-<platform_name>-mgmt-cron`
* Configure CRON schedules
    * Update each of the functions (`StartAdxCluster`, `StartAks`, `StopAdxCluster`, `StopAks`) by updating their file `function.json` (`schedule` parameter).
    * CRON examples: 
        * `0 0 7 * * 1-5` for Monday to Friday at 8:00am GMT+1 (Paris winter time)
        * `0 0 19 * * 1-5` for Monday to Friday at 8:00pm GMT+1 (Paris winter time)
* From VSCode Azure Extension, deploy the code to the Azure Function App you just created before
* In Azure Portal > Function App > Configuration, add the following environment vairables:
    * ADX_CLUSTERS_CONFIG (example : [{"cluster_name": "cluster1", "resource_group": "group1"}, {"cluster_name": "cluster2", "resource_group": "group2"}, ...])
    * AKS_CLUSTER_NAME
    * AKS_RESOURCE_GROUP
    * AZURE_SUBSCRIPTION_ID

    * AZURE_CLIENT_ID
    * AZURE_CLIENT_SECRET
    * AZURE_TENANT_ID
* In Azure Portal > Functions, disable the functions`ResumePowerBI`, `StartStudioVM`, `StopPowerBI` and `StopStudioVM` that are not used so far.

You are done, then you can disable/enable each function from Azure portal in order to suspend/activate the stop/start of the platform components.
    
### 3. Trigger configuration

The default time zone used with the CRON expressions is Coordinated Universal Time (UTC). 
To have your CRON expression based on another time zone, create an app setting for your function app named WEBSITE_TIME_ZONE.

**NOTE:** 

> WEBSITE_TIME_ZONE and TZ are not currently supported on the Linux Consumption plan.


```json
~/function.json
    {
        "scriptFile": "__init__.py",
        "bindings": [
            {
                "name": "mytimer",
                "type": "timerTrigger",
                "direction": "in",
                "schedule": "0 0 18 * * 1-5"
            }
        ]
    }
```
> The 'Stop' timer is using the schedule 'Cron: '0 0 18 * * 1-5'' and the local time zone: '(UTC) Coordinated Universal Time'

> For example, Europe/Paris Time zone (Linux) currently uses UTC+02:00 during summer time and UTC+01:00 during winter time.
