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
  tags                = var.tags
}
