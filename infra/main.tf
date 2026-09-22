# Azure Security Evidence Assistant — infrastructure entry point
#
# Not yet implemented. Milestone M1 deploys the resource set defined in
# docs/DESIGN.md section 7: Azure Functions, Azure AI Search, Storage
# (Table), Application Insights / Log Analytics, and the role assignments
# granting the Function's managed identity least-privilege access.
#
# See docs/adr/ADR-001-terraform.md              (why Terraform)
#     docs/adr/ADR-003-search-tier.md            (search tier is chosen at apply time)
#     docs/adr/ADR-006-disposable-cloud-environment.md  (apply, demo, destroy)
#     docs/adr/ADR-007-terraform-state-backend.md       (where state lives)
