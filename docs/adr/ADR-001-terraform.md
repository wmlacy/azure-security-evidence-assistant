# ADR-001 — Use Terraform for Infrastructure as Code

**Status:** Accepted

## Context

The project is Azure-native and must demonstrate repeatable infrastructure deployment, not only architecture. The runtime is deliberately disposable: resources are created for a work or demonstration session and destroyed afterward, so the infrastructure definition is exercised repeatedly rather than applied once.

That lifecycle sets the requirements. The tool must produce a reviewable diff before it changes anything, treat destruction as a normal operation rather than an afterthought, and reach the Microsoft Entra and GitHub objects that the keyless deployment path depends on, not only Azure resources.

## Decision

Terraform is used for v1 infrastructure, with the `azurerm` provider as the primary provider.

## Consequences

**Positive**

- `terraform plan` produces a reviewable diff before any change is applied, which matches the change-control discipline the project applies to its own architecture
- `terraform destroy` is a first-class operation, reinforcing the disposable-runtime lifecycle in ADR-006
- One tool and one provider ecosystem covers Azure resources, Entra application objects, and GitHub repository configuration used by the keyless deployment path
- Supports modular infrastructure definitions and works cleanly with GitHub Actions OIDC

**Tradeoff**

- Terraform state must be stored, versioned, and protected. The state backend is recorded separately in ADR-007.
- New Azure resource types and API versions can reach the `azurerm` provider later than they reach the underlying Azure Resource Manager APIs

Both tradeoffs are acceptable. The services in scope are established rather than preview-only, and state handling is treated as a deliberate design decision rather than incidental overhead.
