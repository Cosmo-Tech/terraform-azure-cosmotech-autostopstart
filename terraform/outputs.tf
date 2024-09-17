output "function_app_name" {
  description = "The name of the Function App"
  value       = module.azure_functions.function_app_name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Function App"
  value       = module.azure_functions.function_app_default_hostname
}

output "function_app_id" {
  description = "The ID of the Function App"
  value       = module.azure_functions.function_app_id
}