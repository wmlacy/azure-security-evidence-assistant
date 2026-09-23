# Outputs consumed by the seed and demo steps: endpoints and resource names
# only. No keys or connection secrets are output; access is keyless per
# docs/adr/ADR-004-keyless-auth.md.

output "resource_group_name" {
  description = "The disposable resource group. This is what teardown targets."
  value       = azurerm_resource_group.project.name
}

output "search_endpoint" {
  value = "https://${azurerm_search_service.main.name}.search.windows.net"
}

output "search_sku" {
  description = "Recorded so evaluation results can state the tier they were produced on."
  value       = azurerm_search_service.main.sku
}

output "openai_endpoint" {
  value = azurerm_cognitive_account.openai.endpoint
}

output "openai_embedding_deployment" {
  value = azurerm_cognitive_deployment.embedding.name
}

output "openai_mapping_deployment" {
  value = azurerm_cognitive_deployment.mapping.name
}

output "storage_account_name" {
  value = azurerm_storage_account.app.name
}

output "function_app_name" {
  value = azurerm_function_app_flex_consumption.main.name
}

output "function_principal_id" {
  description = "The identity that holds every application role assignment."
  value       = azurerm_function_app_flex_consumption.main.identity[0].principal_id
}

output "teardown_command" {
  description = "Destroys the application resources. Never touches the state resource group."
  value       = "terraform destroy"
}
