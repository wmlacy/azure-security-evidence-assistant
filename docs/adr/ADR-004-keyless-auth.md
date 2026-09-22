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
