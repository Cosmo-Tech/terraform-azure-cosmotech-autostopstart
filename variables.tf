# variable "new_resource_group" {
#   description = "Whether to create a new resource group"
#   type        = bool
#   default     = false
# }

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "use_existing_storage_account" {
  description = "Set to true to use an existing storage account, false to create a new one"
  type        = bool
  default     = false
}

variable "holiday_country" {
  description = "The country code for holidays"
  type        = string
  default     = "FR"
}

variable "solidarity_day" {
  description = "The date of the solidarity day (format: DD-MM)"
  type        = string
}

variable "azure_subscription_id" {
  description = "The Azure Subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "The Azure Tenant ID"
  type        = string
}

variable "adx_clusters_config" {
  description = "JSON configuration for ADX clusters, format : [{\"cluster_name\": \"cluster1\", \"resource_group\": \"group1\"}]"
  type        = string
}

variable "aks_resource_group" {
  description = "The resource group name for AKS"
  type        = string
}

variable "aks_cluster_name" {
  description = "The AKS cluster name"
  type        = string
}

variable "powerbi_resource_group" {
  description = "The resource group name for Power BI"
  type        = string
}

variable "powerbi_name" {
  description = "The Power BI instance name"
  type        = string
}

variable "vm_resource_group" {
  description = "The resource group name for the VM"
  type        = string
}

variable "vm_name" {
  description = "The VM name"
  type        = string
}

variable "stop_minutes" {
  type = number
}

variable "stop_hours" {
  type = number
}

variable "start_minutes" {
  type = number
}

variable "start_hours" {
  type = number
}

variable "disable_start_aks" {
  type = bool
}

variable "disable_start_adx" {
  type = bool
}

variable "disable_start_powerbi" {
  type = bool
}

variable "disable_start_studiovm" {
  type = bool
}

variable "disable_stop_aks" {
  type = bool
}

variable "disable_stop_adx" {
  type = bool
}

variable "disable_stop_powerbi" {
  type = bool
}

variable "disable_stop_studiovm" {
  type = bool
}