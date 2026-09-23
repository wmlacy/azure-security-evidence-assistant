# Input variables. Values are supplied per environment; no defaults encode
# a subscription, tenant, or region that would deploy something unintended.

variable "location" {
  description = "Azure region for all project resources."
  type        = string
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "Disposable resource group holding every application resource. Never the state resource group."
  type        = string
  default     = "rg-asea-app"
}

variable "name_prefix" {
  description = "Short prefix for generated resource names."
  type        = string
  default     = "asea"
}

variable "search_sku" {
  description = <<-EOT
    Azure AI Search tier. ADR-003 selects "free" for development and the portfolio
    deployment, having verified that it supports managed identity, Entra RBAC with
    API keys disabled, and the vector retrieval path.

    Changing this to a billable tier is a recreation, not an in-place upgrade:
    Azure does not permit switching to or from the free tier, so Terraform destroys
    and recreates the service and all indexes must be rebuilt.
  EOT
  type        = string
  default     = "free"

  validation {
    condition     = contains(["free", "basic", "standard"], var.search_sku)
    error_message = "search_sku must be one of: free, basic, standard."
  }
}

variable "python_version" {
  description = "Python runtime for the Function App. Pinned to 3.12 per the M0 checklist."
  type        = string
  default     = "3.12"
}

variable "mapping_model" {
  description = "Model deployment used to draft control-to-evidence mappings."
  type = object({
    name     = string
    version  = string
    sku_name = string
    capacity = number
  })
  default = {
    name     = "gpt-4.1-mini"
    version  = "2025-04-14"
    sku_name = "GlobalStandard"
    capacity = 10
  }
}

variable "embedding_model" {
  description = "Model deployment used to embed evidence chunks and queries."
  type = object({
    name     = string
    version  = string
    sku_name = string
    capacity = number
  })
  default = {
    name     = "text-embedding-3-small"
    version  = "1"
    sku_name = "GlobalStandard"
    capacity = 10
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    project   = "azure-security-evidence-assistant"
    lifecycle = "disposable"
    data      = "synthetic-only"
  }
}

variable "table_mappings" {
  description = "Table holding draft and accepted mappings. Created by application code, not Terraform; see storage.tf."
  type        = string
  default     = "mappings"
}

variable "table_audit" {
  description = "Table holding reviewer transition audit records. Created by application code, not Terraform; see storage.tf."
  type        = string
  default     = "reviewaudit"
}
