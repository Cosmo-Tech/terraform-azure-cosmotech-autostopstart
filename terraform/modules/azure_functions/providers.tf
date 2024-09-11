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
  }
  required_version = ">= 0.13"
}