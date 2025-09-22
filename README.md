# Terraform - Azure Functions Timer Trigger 

This repository contains source code of azure functions for auto stop/start AKS and ADX services.

* clone repository
* configure terraform.tfvars
    * CRON schedules are UTC timezone
    * functions can be disabled

```
./run-terraform.sh
```

/!\ states are not stored, in case of modification needed, delete the old resource group and deploy again