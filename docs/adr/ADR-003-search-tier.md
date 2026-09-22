# ADR-003 — Disposable Azure AI Search Tier

**Status:** Accepted with deployment-time verification

## Context

The v1 corpus is tiny and the project runs intermittently. Cost matters, but so does the identity story. Azure AI Search Free is useful for simple experiments, but current Microsoft documentation states that the Free tier does not support managed identities for Microsoft Entra ID authentication and authorization. Dedicated billable tiers are billed hourly, and Microsoft also offers a Serverless Developer tier in preview for bursty workloads in supported regions.

## Decision

No paid search service is left running permanently. At deployment time:

1. Prefer a short-lived search option that supports the identity features required by the final demonstration.
2. Consider Serverless Developer where it is available and its preview constraints are acceptable.
3. Use a short-lived Dedicated Basic deployment if needed to demonstrate managed identity and RBAC cleanly.
4. Use Free only for early retrieval experiments where the identity limitation is explicitly documented.
5. Delete the project resource group after the session.

## Cost rule

Target no more than $15 USD total Azure spend. Cost Management alerts are configured near $5, $10, and $15. Budgets alert rather than enforce a hard spending stop, so teardown is the primary control.

## Consequences

**Positive**

- Preserves a credible keyless and RBAC-based identity model
- Avoids paying idle dedicated search costs
- Makes the deployment reproducible instead of permanently hosted
- Forces explicit cost and feature tradeoff documentation

**Tradeoffs**

- Search tier and region must be re-verified at deployment time
- Preview serverless behavior can change
- A live demonstration requires a fresh deployment rather than an always-on endpoint

## Platform note

Verified against Microsoft Learn on 2026-09-11: Azure AI Search Free is limited for managed-identity scenarios; Dedicated tiers are prorated by provisioned capacity; Serverless Developer is preview and consumption-based in supported regions.
