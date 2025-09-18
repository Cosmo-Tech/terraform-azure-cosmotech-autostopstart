# Azure Functions Timer Trigger 

This repository contains source code of azure functions for auto stop/start AKS and ADX services.

## Terraform deployment
* clone repository
* configure terraform.tfvars
    * CRON schedules are UTC timezone

```
terraform init
terraform plan -out tfplan
```
```
terraform apply tfplan
```
