# ADR-006 — GitHub Is Durable; Azure Runtime Is Disposable

**Status:** Accepted

## Context

This is a demonstration project, not a production SaaS product. The synthetic corpus, controls, source code, infrastructure definitions, evaluation fixtures, screenshots, and documented results must survive indefinitely without requiring an always-on Azure bill.

## Decision

The GitHub repository is the permanent source of truth. Azure services are an ephemeral runtime that can be created from Terraform, seeded from repository evidence, exercised, measured, and destroyed.

The normal resting state of the project is:

```text
GitHub repository:                present
Synthetic evidence:               present in repo
Architecture/evaluation results:  present in repo
Azure runtime resources:          intentionally absent
```

When development or a live demonstration is required:

```text
terraform apply → seed evidence → run/test/demo → capture results → terraform destroy
```

## Cost controls

- One project resource group for disposable runtime resources
- One separate state resource group that is never torn down (see the scope note below)
- Target cumulative Azure spend: ≤ $15 USD
- Cost alerts near $5 / $10 / $15
- Prompt teardown after each session
- No architecture decision may assume a permanently running paid resource

Azure budgets are used for visibility and notification; they are not treated as a guaranteed hard cap.

## Scope of teardown

"Disposable" applies to runtime resources, not to Terraform state. ADR-007 places state in a storage account in a dedicated resource group that deliberately survives teardown, because losing state would orphan any resource that outlived an interrupted destroy. Its standing cost is a few kilobytes of locally redundant storage.

Teardown therefore targets the project resource group by name. It is never expressed as "delete every resource group in the subscription."

## Consequences

**Positive**

- Near-zero intended idle cloud cost
- Strong infrastructure-as-code demonstration
- The complete case study can be inspected without a live endpoint
- A fresh deployment proves reproducibility
- Synthetic source data remains versioned and reviewable

**Tradeoffs**

- Live demonstrations require redeployment
- Some screenshots and results can become stale if Azure services or model versions change
- Deployment documentation must be good enough to recreate the environment

## Rationale note

The public corpus lives in the repository because it is synthetic. In a production implementation, controlled object storage such as Azure Blob Storage would be appropriate. The runtime is deliberately disposable so it can be recreated from infrastructure-as-code and torn down after use.
