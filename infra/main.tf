# Azure Security Evidence Assistant — infrastructure entry point
#
# Deploys the resource set defined in docs/DESIGN.md section 7 into a single
# disposable resource group. The Terraform state backend lives in a separate
# permanent resource group and is never managed here.
#
# See docs/adr/ADR-001-terraform.md              (why Terraform)
#     docs/adr/ADR-003-search-tier.md            (why the Free search tier)
#     docs/adr/ADR-004-keyless-auth.md           (no keys anywhere)
#     docs/adr/ADR-006-disposable-cloud-environment.md  (apply, demo, destroy)
#     docs/adr/ADR-007-terraform-state-backend.md       (where state lives)

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  # Storage account names allow only lowercase letters and digits, max 24 chars.
  storage_name = substr("st${var.name_prefix}${random_string.suffix.result}", 0, 24)
  base         = "${var.name_prefix}-${random_string.suffix.result}"
}

resource "azurerm_resource_group" "project" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
