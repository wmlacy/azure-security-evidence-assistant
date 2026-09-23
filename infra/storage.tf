# Application storage: Table Storage for draft mappings, review records, and
# audit entries, plus the deployment container the Function App runs from.
#
# Shared key authorization is disabled, so this account accepts only Microsoft
# Entra tokens. Nothing in this configuration produces a connection string.

resource "azurerm_storage_account" "app" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.project.name
  location                 = azurerm_resource_group.project.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false

  tags = var.tags

  lifecycle {
    postcondition {
      condition     = self.shared_access_key_enabled == false
      error_message = "ADR-004 violation: shared key authentication is enabled on the application storage account."
    }
  }
}

# Deployment package container for the Flex Consumption Function App.
resource "azurerm_storage_container" "deployments" {
  name               = "deployments"
  storage_account_id = azurerm_storage_account.app.id
}

# Draft and accepted mappings. See docs/DESIGN.md section 8.
resource "azurerm_storage_table" "mappings" {
  name                 = "mappings"
  storage_account_name = azurerm_storage_account.app.name
}

# Immutable-by-convention record of reviewer transitions.
resource "azurerm_storage_table" "reviewaudit" {
  name                 = "reviewaudit"
  storage_account_name = azurerm_storage_account.app.name
}
