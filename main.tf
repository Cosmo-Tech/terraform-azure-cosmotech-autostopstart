locals {
  azure_subscription_id = var.azure_subscription_id
  azure_tenant_id       = var.azure_tenant_id
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  resource_group_name   = var.resource_group_name
  new_resource_group    = var.new_resource_group
  location              = var.location
  app_service_plan_name = var.app_service_plan_name
  function_app_name     = var.function_app_name

  # If existing storage account
  use_existing_storage_account   = var.use_existing_storage_account
  storage_account_name           = var.use_existing_storage_account ? var.storage_account_name : azurerm_storage_account.sa[0].name
  storage_account_resource_group = var.use_existing_storage_account ? var.resource_group_name : (var.new_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name)
  storage_account_access_key     = var.use_existing_storage_account ? data.azurerm_storage_account.existing_sa[0].primary_access_key : azurerm_storage_account.sa[0].primary_access_key
  storage_connection_string      = var.use_existing_storage_account ? data.azurerm_storage_account.existing_sa[0].primary_connection_string : azurerm_storage_account.sa[0].primary_connection_string

  holiday_country        = var.holiday_country
  solidarity_day         = var.solidarity_day
  adx_clusters_config    = var.adx_clusters_config
  aks_resource_group     = var.aks_resource_group
  aks_cluster_name       = var.aks_cluster_name
  powerbi_resource_group = var.powerbi_resource_group
  powerbi_name           = var.powerbi_name
  vm_resource_group      = var.vm_resource_group
  vm_name                = var.vm_name
  start_hours            = var.start_hours
  stop_hours             = var.stop_hours
  start_minutes          = var.start_minutes
  stop_minutes           = var.stop_minutes

  tmp_dir = "/tmp/terraform-functions"
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
      #!/bin/sh

      set -e
      set -x

      if ! [ -x "$(command -v zip)" ]; then
        echo "'zip' is not installed. Please install it."
        exit 1
      fi

      dir_tmp=${local.tmp_dir}
      file_archive="$dir_tmp/functions.zip"

      rm -rf $dir_tmp
      mkdir -p $dir_tmp/functions
      cp -R ${path.root}/functions $dir_tmp/

      functions_start="$(ls ${path.root}/functions | grep Start)"
      for fstart in $functions_start; do
        # echo $fstart
        sed -i 's|%KEYSCHEDULE%|0 ${var.start_minutes} ${var.start_hours} * * 1-5|' $dir_tmp/functions/$fstart/function.json
      done

      functions_stop="$(ls ${path.root}/functions | grep Stop)"
      for fstop in $functions_stop; do
        # echo $fstop
        sed -i 's|%KEYSCHEDULE%|0 ${var.stop_minutes} ${var.stop_hours} * * 1-5|' $dir_tmp/functions/$fstop/function.json
      done

      cd $dir_tmp/functions
      zip -r "$file_archive" .

      chmod -R 777 $dir_tmp
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

resource "azurerm_log_analytics_workspace" "app_insights_workspace" {
  name                = "${var.function_app_name}-analytics-workspace"
  location            = var.location
  resource_group_name = var.new_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "app_insights" {
  name                = "${var.function_app_name}-analytics"
  location            = var.location
  resource_group_name = var.new_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.app_insights_workspace.id
  application_type    = "web"
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
    "APPINSIGHTS_INSTRUMENTATIONKEY"           = azurerm_application_insights.app_insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"    = azurerm_application_insights.app_insights.connection_string
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
    "AzureWebJobs.ResumePowerBI.Disabled"      = "0"
    "AzureWebJobs.StartStudioVM.Disabled"      = "0"
    "AzureWebJobs.StopAdxCluster.Disabled"     = "0"
    "AzureWebJobs.StopAks.Disabled"            = "0"
    "AzureWebJobs.StopBowerBI.Disabled"        = "0"
    "AzureWebJobs.StopStudioVM.Disabled"       = "0"
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }

  zip_deploy_file = "${local.tmp_dir}/functions.zip"

  depends_on = [null_resource.package_functions]
}
