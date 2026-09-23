# ADR-004 — Prefer Managed Identity and OIDC

**Status:** Accepted

## Context

A security-focused project should not depend on broad static credentials when Azure-native identity mechanisms can provide narrower, auditable access.

## Decision

The following are used:

- Managed Identity for Azure service-to-service access where supported
- Microsoft Entra ID and RBAC for reviewer authorization
- GitHub Actions OIDC / workload identity federation for Azure deployment
- Key Vault only for residual secrets that cannot be removed through identity-based authentication

## Consequences

Key Vault may be nearly empty. That is intentional. Eliminating a secret is preferable to storing it securely when identity-based access is available.

Role assignments are scoped to the minimum resource and action set required by each code path.

## Terraform state security consideration

Although the application runtime uses managed identity and avoids stored credentials, Terraform state may contain sensitive resource attributes returned by Azure APIs. Azure returns values such as storage account keys, search service admin keys, and workspace shared keys as read-only attributes on the resources themselves, and Terraform records them in state whether or not the configuration references them. The configuration references none of them.

Those values are inert in this deployment, because local and shared key authentication is disabled on every service that issues them and Azure rejects their use. They are nonetheless present in the state file.

The state backend is therefore treated as sensitive infrastructure data. Access is restricted through Microsoft Entra ID RBAC, public access is disabled, shared key authentication is disabled, and state is not stored locally or committed to source control. See [ADR-007](ADR-007-terraform-state-backend.md).

Two distinct risks follow, and they need different controls:

| Risk | Control |
|---|---|
| Sensitive attributes at rest in the state file | Backend hardening: Entra-only access, no public access, no shared key, versioning enabled, no local state |
| Accidental display of values in CLI output or CI logs | `sensitive = true` on any output carrying such a value, and a standing rule that no output exposes a key or connection string |

This is a consequence of state-based infrastructure management, noted in the tradeoffs in [ADR-001](ADR-001-terraform.md), and it is accepted knowingly rather than overlooked.
