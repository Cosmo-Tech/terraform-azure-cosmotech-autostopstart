# Azure Functions Timer Trigger 

    This repository contains source code of azure functions for auto stop/start AKS and ADX services.

</br>

## 1. App registration
---

    Register an application with owner access to resource group and add a client secret

</br>

## 2. Configuration
---

    Individual functions in a function app are deployed together and are scaled together. 
    All functions in the same function app share resources, per instance, as the function app scales.

    Environment variables:
    ---

    * ADX_CLUSTER_NAME
    * ADX_RESOURCE_GROUP
    * AKS_CLUSTER_NAME
    * AKS_RESOURCE_GROUP

    * AZURE_CLIENT_ID
    * AZURE_CLIENT_SECRET
    * AZURE_SUBSCRIPTION_ID
    * AZURE_TENANT_ID


    
## Trigger configuration
---

The default time zone used with the CRON expressions is Coordinated Universal Time (UTC). 

To have your CRON expression based on another time zone, create an app setting for your function app named WEBSITE_TIME_ZONE.

---
**NOTE:** 

> WEBSITE_TIME_ZONE and TZ are not currently supported on the Linux Consumption plan.
---


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

> For example, Europe/Paris Timezone (Linux) currently uses UTC+02:00 during summer time.
