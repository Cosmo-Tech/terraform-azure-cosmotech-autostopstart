module "azure_functions" {
  source = "./modules/azure_functions"

  azure_subscription_id = var.azure_subscription_id
  azure_tenant_id       = var.azure_tenant_id
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  resource_group_name   = var.resource_group_name
  new_resource_group    = var.new_resource_group
  location              = var.location
  storage_account_name  = var.storage_account_name
  app_service_plan_name = var.app_service_plan_name
  function_app_name     = var.function_app_name

  # If existing storage account
  use_existing_storage_account = var.use_existing_storage_account

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
}