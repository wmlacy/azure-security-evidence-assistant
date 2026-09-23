# Telemetry. Validation outcomes, retrieval metrics, token use, latency, and
# review transitions are measurable here.
#
# docs/DATA_STATEMENT.md requires that raw evidence content is never written to
# application telemetry. That is enforced in application code, not by this
# configuration; the retention setting below only limits how long whatever is
# emitted is kept.

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.base}"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${local.base}"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  # Disables instrumentation-key ingestion. With this set, the instrumentation
  # key inside the connection string no longer authenticates anything: telemetry
  # must be submitted with a Microsoft Entra token by a principal holding
  # Monitoring Metrics Publisher. The connection string degrades from a
  # credential to an endpoint identifier.
  local_authentication_enabled = false

  tags = var.tags

  lifecycle {
    postcondition {
      condition     = self.local_authentication_enabled == false
      error_message = "ADR-004 violation: instrumentation key ingestion is enabled on Application Insights."
    }
  }
}
