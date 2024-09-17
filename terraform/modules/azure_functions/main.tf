locals {
  storage_account_name           = var.use_existing_storage_account ? var.storage_account_name : azurerm_storage_account.sa[0].name
  storage_account_resource_group = var.use_existing_storage_account ? var.resource_group_name : (var.new_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name)
  storage_account_access_key     = var.use_existing_storage_account ? data.azurerm_storage_account.existing_sa[0].primary_access_key : azurerm_storage_account.sa[0].primary_access_key
  storage_connection_string      = var.use_existing_storage_account ? data.azurerm_storage_account.existing_sa[0].primary_connection_string : azurerm_storage_account.sa[0].primary_connection_string
}

resource "random_string" "function_app_version" {
  length  = 8
  special = false
  upper   = false
}

resource "null_resource" "package_functions" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      set -e
      set -x

      if ! command -v zip &> /dev/null
      then
          echo "'zip' is not installed. Please install it."
          exit 1
      fi

      FUNCTIONS_DIR="${path.root}/../functions"
      ZIP_FILE="../terraform/functions.zip"

      rm -f "functions.zip"

      cd "$FUNCTIONS_DIR" && zip -r "$ZIP_FILE" . || exit 1
    EOT
  }
}

resource "azurerm_resource_group" "rg" {
  count    = var.new_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_storage_account" "existing_sa" {
  count               = var.use_existing_storage_account ? 1 : 0
  name                = local.storage_account_name
  resource_group_name = local.storage_account_resource_group
}

resource "azurerm_storage_account" "sa" {
  count                    = var.use_existing_storage_account ? 0 : 1
  name                     = var.storage_account_name
  resource_group_name      = var.new_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "asp" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.new_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "fa" {
  name                       = var.function_app_name
  location                   = var.location
  resource_group_name        = var.new_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = local.storage_account_name
  storage_account_access_key = local.storage_account_access_key

  app_settings = {
    "ENABLE_ORYX_BUILD"                        = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"           = "true"
    "AzureWebJobsStorage"                      = local.storage_connection_string
    "FUNCTIONS_EXTENSION_VERSION"              = "~4"
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = local.storage_connection_string
    "WEBSITE_CONTENTSHARE"                     = lower(var.function_app_name)
    "FUNCTIONS_WORKER_RUNTIME"                 = "python"
    "HOLIDAY_COUNTRY"                          = var.holiday_country
    "SOLIDARITY_DAY"                           = var.solidarity_day
    "AZURE_SUBSCRIPTION_ID"                    = var.azure_subscription_id
    "AZURE_TENANT_ID"                          = var.azure_tenant_id
    "AZURE_CLIENT_ID"                          = var.azure_client_id
    "AZURE_CLIENT_SECRET"                      = var.azure_client_secret
    "ADX_CLUSTERS_CONFIG"                      = var.adx_clusters_config
    "AKS_RESOURCE_GROUP"                       = var.aks_resource_group
    "AKS_CLUSTER_NAME"                         = var.aks_cluster_name
    "POWERBI_RESOURCE_GROUP"                   = var.powerbi_resource_group
    "POWERBI_NAME"                             = var.powerbi_name
    "VM_RESOURCE_GROUP"                        = var.vm_resource_group
    "VM_NAME"                                  = var.vm_name
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }

  zip_deploy_file = "${path.root}/functions.zip"

  depends_on = [null_resource.package_functions]
}
