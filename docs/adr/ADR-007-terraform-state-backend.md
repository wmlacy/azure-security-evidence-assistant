# ADR-007 — Store Terraform State in a Durable Azure Storage Backend

**Status:** Accepted

## Context

ADR-001 selects Terraform, which requires persistent state. ADR-006 establishes that Azure runtime resources are disposable and that deleting the project resource group is the real cost control. State is therefore the one piece of Azure-side data that must not be deleted with the runtime: losing it orphans any resources that survive an interrupted destroy and removes the record needed to clean them up.

Two options were considered.

Local state on the workstation requires no standing Azure resource and no bootstrap step, but it cannot be read by GitHub Actions, which restricts the CI path to validation and plan only. It is also lost with the workstation.

A remote `azurerm` backend stores state in Azure Blob Storage. It is readable by both the workstation and GitHub Actions under the same Entra identity model, and the backend acquires a blob lease for state locking, so no separate lock resource is required.

## Decision

Terraform state is stored in an `azurerm` backend: a storage account and blob container in a dedicated, durable resource group that is separate from the disposable project resource group.

The backend storage account is configured for keyless access, consistent with ADR-004:

- Shared key authorization disabled, so the storage account accepts only Microsoft Entra tokens and no account key exists to leak or rotate
- Public blob access disabled
- Blob versioning enabled so a corrupted or truncated state file can be recovered

Two callers reach the backend, and both present an Entra token:

| Caller | How the Entra identity is obtained | What reaches the backend |
|---|---|---|
| Local workstation | `az login` | An Entra access token for the signed-in user |
| GitHub Actions | Workload identity federation: the workflow's OIDC token is exchanged with Entra ID for an access token for a service principal | An Entra access token for that service principal |

OIDC is the federation trust that lets GitHub Actions obtain an Azure identity without a stored client secret. It is not itself the protocol used against Blob Storage. Terraform authenticates to the state container with the resulting Entra token in both cases, which is why `use_azuread_auth` is the only backend setting the two paths need in common.

The backend resource group is created once as a bootstrap step, outside the main Terraform configuration, because it must exist before the first `terraform init`.

## Consequences

**Positive**

- State survives resource-group teardown, so an interrupted destroy remains recoverable
- The same state is available to local runs and to GitHub Actions, allowing CI to run a real plan against actual state, with RBAC on the state container scoped per identity
- State locking is provided by blob leases with no additional resource
- Keyless access is preserved end to end

**Tradeoff**

- One Azure resource group now persists between sessions, which is a deliberate exception to the teardown posture in ADR-006 rather than an oversight
- A bootstrap step exists that Terraform does not itself manage
- Teardown tooling must target the project resource group by name and must never target the state resource group

The standing cost is a state file of a few kilobytes in locally redundant storage, which is negligible against the $15 project target. The exception is scoped and named so that "delete the resource group" remains an unambiguous instruction.
