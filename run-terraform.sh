#!/bin/sh

# rm -rf .terraform*
# rm -rf terraform.tfstate*


terraform init
terraform plan -out .terraform.plan
terraform apply .terraform.plan



exit