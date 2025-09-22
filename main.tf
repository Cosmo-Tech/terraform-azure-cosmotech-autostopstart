locals {
  main_name = "${var.aks_resource_group}-autostartstop"

  # If existing storage account
  storage_account_name           = var.use_existing_storage_account ? local.main_name : azurerm_storage_account.sa[0].name
  storage_account_resource_group = var.use_existing_storage_account ? local.main_name : (local.main_name)
  storage_account_access_key     = var.use_existing_storage_account ? data.azurerm_storage_account.existing_sa[0].primary_access_key : azurerm_storage_account.sa[0].primary_access_key
  storage_connection_string      = var.use_existing_storage_account ? data.azurerm_storage_account.existing_sa[0].primary_connection_string : azurerm_storage_account.sa[0].primary_connection_string

  tmp_dir = "/tmp/terraform-functions"
}

resource "azuread_application_registration" "azure_client_app_registration" {
  display_name     = local.main_name
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_application_password" "azure_client_app_registration_secret" {
  application_id = azuread_application_registration.azure_client_app_registration.id
  display_name   = "secret"
}

resource "azuread_service_principal" "azure_client_service_principal" {
  client_id = azuread_application_registration.azure_client_app_registration.client_id
}

resource "azurerm_resource_group" "rg" {
  # count    = var.new_resource_group ? 1 : 0
  name     = local.main_name
  location = var.location
}

resource "azurerm_role_assignment" "azure_client_assignment_aks" {
  scope                = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.aks_resource_group}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.azure_client_service_principal.object_id
  depends_on           = [azuread_application_registration.azure_client_app_registration]
}

resource "azurerm_role_assignment" "azure_client_assignment_adx" {
  for_each             = toset(var.adx_resource_groups)
  scope                = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${each.value}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.azure_client_service_principal.object_id
  depends_on           = [azuread_application_registration.azure_client_app_registration]
}

data "azurerm_storage_account" "existing_sa" {
  count               = var.use_existing_storage_account ? 1 : 0
  name                = local.storage_account_name
  resource_group_name = local.storage_account_resource_group
}

resource "azurerm_storage_account" "sa" {
  count = var.use_existing_storage_account ? 0 : 1
  name                     = replace(lower("${var.aks_resource_group}cron"), "-", "")
  resource_group_name      = local.main_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on               = [azurerm_resource_group.rg]
}

resource "azurerm_service_plan" "asp" {
  name                = local.main_name
  location            = var.location
  resource_group_name = local.main_name
  os_type             = "Linux"
  sku_name            = "Y1"
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = local.main_name
  location            = var.location
  resource_group_name = local.main_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  depends_on          = [azurerm_resource_group.rg]

}

resource "azurerm_application_insights" "app_insights" {
  name                = local.main_name
  location            = var.location
  resource_group_name = local.main_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  depends_on          = [azurerm_resource_group.rg]

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
  depends_on = [azurerm_resource_group.rg]

}

resource "azurerm_linux_function_app" "fa" {
  name                       = local.main_name
  location                   = var.location
  resource_group_name        = local.main_name
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
    "WEBSITE_CONTENTSHARE"                     = replace(lower(local.main_name), "-", "")
    "FUNCTIONS_WORKER_RUNTIME"                 = "python"
    "HOLIDAY_COUNTRY"                          = var.holiday_country
    "SOLIDARITY_DAY"                           = var.solidarity_day
    "AZURE_SUBSCRIPTION_ID"                    = var.azure_subscription_id
    "AZURE_TENANT_ID"                          = var.azure_tenant_id
    "AZURE_CLIENT_ID"                          = azuread_application_registration.azure_client_app_registration.client_id
    "AZURE_CLIENT_SECRET"                      = azuread_application_password.azure_client_app_registration_secret.value
    "ADX_CLUSTERS_CONFIG"                      = var.adx_clusters_config
    "AKS_RESOURCE_GROUP"                       = var.aks_resource_group
    "AKS_CLUSTER_NAME"                         = var.aks_cluster_name
    "POWERBI_RESOURCE_GROUP"                   = var.powerbi_resource_group
    "POWERBI_NAME"                             = var.powerbi_name
    "VM_RESOURCE_GROUP"                        = var.vm_resource_group
    "VM_NAME"                                  = var.vm_name
    "AzureWebJobs.StartAks.Disabled"           = var.disable_start_aks
    "AzureWebJobs.StartAdxCluster.Disabled"    = var.disable_start_adx
    "AzureWebJobs.StartPowerBI.Disabled"       = var.disable_start_powerbi
    "AzureWebJobs.StartStudioVM.Disabled"      = var.disable_start_studiovm
    "AzureWebJobs.StopAks.Disabled"            = var.disable_stop_aks
    "AzureWebJobs.StopAdxCluster.Disabled"     = var.disable_stop_adx
    "AzureWebJobs.StopPowerBI.Disabled"        = var.disable_stop_powerbi
    "AzureWebJobs.StopStudioVM.Disabled"       = var.disable_stop_studiovm
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }

    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
  }

  zip_deploy_file = "${local.tmp_dir}/functions.zip"

  depends_on = [null_resource.package_functions]
}
