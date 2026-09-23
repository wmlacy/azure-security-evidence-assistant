# Microsoft Foundry / Azure OpenAI model endpoints.
#
# local_auth_enabled = false disables API key authentication, so callers present
# Entra tokens. custom_subdomain_name is required for token-based authentication
# against a Cognitive Services account.
#
# Two deployments, matching the two distinct jobs in docs/DESIGN.md: one embeds
# evidence chunks and queries, one drafts the structured mapping. The mapping
# model's output is advisory and can never reach ACCEPTED on its own
# (docs/adr/ADR-005-human-authority-state-machine.md).

resource "azurerm_cognitive_account" "openai" {
  name                = "oai-${local.base}"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  kind                = "OpenAI"
  sku_name            = "S0"

  custom_subdomain_name         = "oai-${local.base}"
  local_auth_enabled            = false
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "embedding"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.embedding_model.name
    version = var.embedding_model.version
  }

  sku {
    name     = var.embedding_model.sku_name
    capacity = var.embedding_model.capacity
  }
}

# Deployments are created sequentially. Azure rejects concurrent deployment
# operations against the same account.
resource "azurerm_cognitive_deployment" "mapping" {
  name                 = "mapping"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.mapping_model.name
    version = var.mapping_model.version
  }

  sku {
    name     = var.mapping_model.sku_name
    capacity = var.mapping_model.capacity
  }

  depends_on = [azurerm_cognitive_deployment.embedding]
}
