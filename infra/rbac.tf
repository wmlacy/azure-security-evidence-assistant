# Role assignments.
#
# Each identity receives only the roles its code path requires
# (docs/DESIGN.md, "Least privilege"). These assignments are what make the
# keyless model actually work: with API keys and shared keys disabled across
# Search, OpenAI, and Storage, RBAC is the only access path that exists.
#
# Note the deliberate omission: the Function App's identity is NOT granted
# Search Service Contributor, which can read admin API keys. Index and
# schema creation is an operator task run from the ingestion script, not
# something the running application needs.

locals {
  function_principal_id = azurerm_function_app_flex_consumption.main.identity[0].principal_id
}

# --- Function App -> Azure AI Search ---------------------------------------

# Read and write documents, and query indexes.
resource "azurerm_role_assignment" "function_search_data" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = local.function_principal_id
  principal_type       = "ServicePrincipal"
}

# --- Function App -> Azure OpenAI ------------------------------------------

# Call embedding and chat completion endpoints. Does not permit managing
# deployments or reading account keys.
resource "azurerm_role_assignment" "function_openai" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = local.function_principal_id
  principal_type       = "ServicePrincipal"
}

# --- Function App -> Storage ------------------------------------------------

# Persist mappings and audit records.
resource "azurerm_role_assignment" "function_tables" {
  scope                = azurerm_storage_account.app.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = local.function_principal_id
  principal_type       = "ServicePrincipal"
}

# The Flex Consumption host reads its own deployment package from the
# deployments container using this identity. Without it the app cannot start.
resource "azurerm_role_assignment" "function_blob" {
  scope                = azurerm_storage_account.app.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = local.function_principal_id
  principal_type       = "ServicePrincipal"
}

# --- Function App -> Telemetry ---------------------------------------------

resource "azurerm_role_assignment" "function_metrics" {
  scope                = azurerm_application_insights.main.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = local.function_principal_id
  principal_type       = "ServicePrincipal"
}

# --- Operator -> data planes ------------------------------------------------
#
# The signed-in operator seeds the corpus and creates the index from a local
# script. With key authentication disabled these assignments are the only way
# that script can reach the data planes.

resource "azurerm_role_assignment" "operator_search_service" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Service Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_role_assignment" "operator_search_data" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_role_assignment" "operator_openai" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_role_assignment" "operator_tables" {
  scope                = azurerm_storage_account.app.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_role_assignment" "operator_blob" {
  scope                = azurerm_storage_account.app.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}
