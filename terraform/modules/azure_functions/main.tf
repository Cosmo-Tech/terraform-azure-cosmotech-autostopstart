resource "random_string" "function_app_version" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  count    = var.new_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "sa" {
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

# Create zip package
resource "null_resource" "package_functions" {
  provisioner "local-exec" {
    command = "${path.root}/../scripts/package_functions.sh"
    working_dir = "${path.root}/.."
  }
}

resource "azurerm_storage_container" "function_apps" {
  name                  = "function-apps"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "function_app_code" {
  name                   = "functionapp-${random_string.function_app_version.result}.zip"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.function_apps.name
  type                   = "Block"
  source                 = "${path.root}/../functions.zip"

  depends_on = [null_resource.package_functions]
}

resource "azurerm_linux_function_app" "fa" {
  name                       = var.function_app_name
  location                   = var.location
  resource_group_name        = var.new_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "WEBSITE_RUN_FROM_PACKAGE" = "https://${azurerm_storage_account.sa.name}.blob.core.windows.net/${azurerm_storage_container.function_apps.name}/${azurerm_storage_blob.function_app_code.name}"
    "HOLIDAY_COUNTRY"          = var.holiday_country
    "SOLIDARITY_DAY"           = var.solidarity_day
    "AZURE_SUBSCRIPTION_ID"    = var.azure_subscription_id
    "AZURE_TENANT_ID"          = var.azure_tenant_id
    "AZURE_CLIENT_ID"          = var.azure_client_id
    "AZURE_CLIENT_SECRET"      = var.azure_client_secret
    "ADX_CLUSTERS_CONFIG"      = var.adx_clusters_config
    "AKS_RESOURCE_GROUP"       = var.aks_resource_group
    "AKS_CLUSTER_NAME"         = var.aks_cluster_name
    "POWERBI_RESOURCE_GROUP"   = var.powerbi_resource_group
    "POWERBI_NAME"             = var.powerbi_name
    "VM_RESOURCE_GROUP"        = var.vm_resource_group
    "VM_NAME"                  = var.vm_name
  }

  site_config {
    linux_fx_version = "python|3.11"
  }
}
