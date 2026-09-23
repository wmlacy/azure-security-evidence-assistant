# Outputs consumed by the seed and demo steps.
#
# Standing rule: no output exposes a key, connection string, shared access
# signature, or admin credential. Every value below is an endpoint, a resource
# name, or an identifier that is not usable for authentication on its own.
#
# None of the current outputs are therefore marked sensitive. Marking a
# non-secret as sensitive would hide values the seeding script needs while
# protecting nothing, and would make a genuinely sensitive output harder to
# notice later.
#
# If a future output ever carries provider-returned credential material, it
# must be marked `sensitive = true`. That suppresses CLI and CI log display; it
# does not remove the value from state. State-at-rest is addressed separately
# by the backend hardening in docs/adr/ADR-007-terraform-state-backend.md.
#
# See docs/adr/ADR-004-keyless-auth.md, "Terraform state security
# consideration", for why these are two distinct risks.

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
