terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.54.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
  required_version = ">= 0.13"
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id = var.azure_tenant_id
}