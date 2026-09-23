# Azure Functions on the Flex Consumption plan.
#
# Flex Consumption is chosen over the older Consumption plan for one concrete
# reason: it supports identity-based connections for the runtime's own storage
# account. On Consumption, AzureWebJobsStorage requires a connection string
# containing an account key, which would contradict ADR-004 and would be
# impossible here anyway, since the storage account has shared key access
# disabled.
#
# storage_authentication_type = "SystemAssignedIdentity" means the host reads
# its deployment package using the Function App's own managed identity.

resource "azurerm_service_plan" "functions" {
  name                = "plan-${local.base}"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = var.tags
}

resource "azurerm_function_app_flex_consumption" "main" {
  name                = "func-${local.base}"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  service_plan_id     = azurerm_service_plan.functions.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.app.primary_blob_endpoint}${azurerm_storage_container.deployments.name}"
  storage_authentication_type = "SystemAssignedIdentity"

  runtime_name    = "python"
  runtime_version = var.python_version

  https_only = true

  # Removes the SCM basic-authentication publishing credential, which is an
  # account-scoped username and password that bypasses Entra entirely.
  # Deployment uses the managed identity path instead.
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.main.connection_string
  }

  # Endpoints and names only. No keys or connection strings: every value here is
  # resolved at runtime through the Function App's managed identity.
  app_settings = {
    AZURE_SEARCH_ENDPOINT             = "https://${azurerm_search_service.main.name}.search.windows.net"
    AZURE_SEARCH_INDEX_NAME           = "evidence-chunks"
    AZURE_OPENAI_ENDPOINT             = azurerm_cognitive_account.openai.endpoint
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT = azurerm_cognitive_deployment.embedding.name
    AZURE_OPENAI_MAPPING_DEPLOYMENT   = azurerm_cognitive_deployment.mapping.name
    AZURE_STORAGE_ACCOUNT_NAME        = azurerm_storage_account.app.name

    # Application Insights ingestion authenticates with the Function App's
    # managed identity rather than the instrumentation key. Required because
    # local authentication is disabled on the component.
    APPLICATIONINSIGHTS_AUTHENTICATION_STRING = "Authorization=AAD"
    AZURE_TABLE_MAPPINGS                      = azurerm_storage_table.mappings.name
    AZURE_TABLE_AUDIT                         = azurerm_storage_table.reviewaudit.name
    RETRIEVAL_TOP_K                           = "5"
    PROMPT_VERSION                            = "v1"
    SCHEMA_VERSION                            = "v1"
  }

  tags = var.tags

  lifecycle {
    postcondition {
      condition     = self.storage_authentication_type == "SystemAssignedIdentity"
      error_message = "ADR-004 violation: the Function App host is not using managed identity for its storage connection."
    }
    postcondition {
      condition     = self.webdeploy_publish_basic_authentication_enabled == false
      error_message = "ADR-004 violation: SCM basic authentication publishing credentials are enabled."
    }
  }
}
