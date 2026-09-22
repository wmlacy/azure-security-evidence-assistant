# Provider and backend configuration.
#
# The backend resource group, storage account, and container are created by
# the bootstrap step described in docs/adr/ADR-007-terraform-state-backend.md,
# because they must exist before the first `terraform init`.
#
# Backend values are supplied at init time rather than hardcoded:
#   terraform init -backend-config=backend.hcl
#
# `use_azuread_auth` makes the backend authenticate to Blob Storage with a
# Microsoft Entra token instead of a storage account key. Locally that token
# comes from `az login`; in GitHub Actions the workflow first exchanges its
# OIDC token with Entra ID for a service principal token, and Terraform uses
# that. The backend itself never sees OIDC -- only the resulting Entra token.
# See docs/adr/ADR-004-keyless-auth.md and ADR-007.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}
}
