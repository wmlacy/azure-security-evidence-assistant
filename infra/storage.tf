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

  # With shared key access disabled, creating this container is a data plane
  # call authorized by Entra RBAC. The operator's role assignment must exist
  # first or the call is refused.
  depends_on = [azurerm_role_assignment.operator_blob]
}

# Table Storage tables are deliberately NOT managed by Terraform.
#
# The azurerm provider's storage table resource reads and writes table ACLs
# through the Storage data plane using shared key authentication. That call is
# refused by this account, which sets shared_access_key_enabled = false, and the
# provider has no Entra fallback for it. Every plan would fail on the ACL read.
#
# Two tables are required, "mappings" and "reviewaudit" (docs/DESIGN.md
# section 8). They are created idempotently by the ingestion and review code
# using DefaultAzureCredential, which is the same pattern already used for the
# Azure AI Search index: both are data plane objects, created by the component
# that owns them rather than by infrastructure code.
#
# Their names are supplied to the Function App through app settings, and the
# role assignments permitting their creation and use are in rbac.tf.
#
# Weakening the storage account to satisfy the provider was rejected. The
# keyless posture in ADR-004 is a requirement, not a preference.
