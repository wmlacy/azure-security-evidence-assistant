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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {
    # Azure creates resources in the project group that Terraform does not
    # manage, such as the "Application Insights Smart Detection" action group.
    # With the default of true, destroy removes everything else and then fails
    # on the non-empty resource group, leaving teardown incomplete. The whole
    # group is disposable per ADR-006, so anything left in it goes with it.
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  # Use Microsoft Entra for Storage data plane operations (containers, tables)
  # instead of an account key. Required here rather than optional: the storage
  # account sets shared_access_key_enabled = false, so key-based data plane
  # calls are refused by Azure and the provider cannot fall back to them.
  storage_use_azuread = true
}
