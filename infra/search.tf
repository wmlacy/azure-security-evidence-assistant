# Azure AI Search — hybrid and vector retrieval over the synthetic evidence corpus.
#
# local_authentication_enabled = false disables API key authentication entirely,
# so the service accepts only Microsoft Entra tokens. ADR-003 records the
# validation confirming this works on the Free tier.
#
# authentication_failure_mode is deliberately not set: it applies only when key
# authentication is still permitted.

resource "azurerm_search_service" "main" {
  name                = "srch-${local.base}"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  sku                 = var.search_sku

  local_authentication_enabled  = false
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
