# ADR-003 — Azure AI Search Tier

**Status:** Accepted

## Context

The v1 corpus is small and the project runs intermittently. Selecting a tier requires separating three questions that are easily conflated: whether a tier meets the identity requirements in ADR-004, whether it can carry the retrieval workload, and what it costs.

An earlier version of this record stated that the Free tier does not support managed identities for Microsoft Entra ID authentication, and used that as the justification for provisioning a billable tier. **That statement was incorrect.** It conflated two distinct mechanisms:

- **Inbound authentication to the search service.** Callers authenticate to the search endpoint with Entra tokens instead of API keys. Microsoft documentation states the prerequisite as a search service in "any region and any tier" with role-based access enabled. No tier restriction applies.
- **An outbound managed identity on the search service.** The service holds its own identity for reaching other Azure resources. This is also available on the Free tier.

### Validation performed

Verified empirically against a Free-tier service in Southeast Asia on 2026-09-23:

| Check | Result |
|---|---|
| System-assigned managed identity assigned to a Free service | Succeeded; a principal ID was issued |
| `disableLocalAuth = true` with `authOptions` cleared | Succeeded; API key authentication disabled entirely |
| Entra RBAC role assignments scoped to the service | Succeeded |
| Create a 1536-dimension HNSW vector index using a bearer token only | HTTP 201 |
| Upload a document with no API key present | HTTP 201 |
| Vector similarity query returning a scored match | HTTP 200 |

The full retrieval path therefore operates on the Free tier with API key authentication switched off.

### Capacity

The v1 synthetic corpus is approximately 10 KB across evidence and control files, against a Free-tier limit of 50 MB total storage, 25 MB vector quota, and three indexes. Embedding the corpus with a 1,536-dimension model consumes a low single-digit percentage of the vector quota. Capacity is not a constraint at this scale.

Ingestion pushes documents directly to the index rather than using an indexer, so the Free tier's indexer execution limits do not apply to the design.

## Decision

**Azure AI Search Free is used for development and for the portfolio deployment.**

The Free tier satisfies the security architecture: it supports identity-based access, permits API key authentication to be disabled, and carries the vector retrieval workload the design requires. It introduces no recurring cost.

Basic is documented as a future production consideration only. It may be selected for production workloads requiring increased capacity, SLA coverage, or enterprise scale. It is not required for the current demonstration architecture.

## Rejected alternative: a short-lived Basic tier

The previously accepted decision was to avoid leaving any paid search service running, to prefer a short-lived Basic deployment when the demonstration needed to show managed identity and RBAC cleanly, and to use Free only for early retrieval experiments with the identity limitation explicitly documented.

That alternative was rejected because the assumption underneath it did not survive testing. Basic was being selected to obtain an identity capability that Free already provides. The remaining differences between the tiers — dedicated infrastructure, SLA coverage, higher capacity, and support for capacity estimation — are real, but none of them is required by this architecture at a corpus size of roughly 10 KB.

Paying an hourly rate for capability the design does not consume, and accepting the teardown risk that comes with an hourly meter, is not justified by the evidence.

## Tier migration is not an in-place upgrade

Microsoft documentation states that pricing tier changes are supported between Basic, S1, S2, and S3, and that a service cannot switch to or from Free, S3 HD, L1, or L2.

Moving from Free to Basic therefore requires a new search service, not a tier change:

- The change is a recreation, not an in-place upgrade
- In Terraform, altering the SKU from `free` to a billable tier forces resource replacement rather than an update in place
- Indexes, index definitions, and indexed documents do not transfer and must be rebuilt
- Rebuild planning is required as part of any future promotion, though the cost is modest here because ingestion is scripted from repository files

Any future promotion is a planned migration with its own rebuild step, and is recorded when it happens.

## Known limitations accepted at the Free tier

- No service-level agreement. Service-level agreements do not cover the Free tier.
- Shared infrastructure. The Free tier runs on physical resources shared with other subscribers, so performance varies and scale-up is not supported.
- Not suitable for capacity estimation. Microsoft advises estimating capacity on a billable tier, because shared resources make measurements unrepresentative. This project does not perform capacity estimation.
- A Free search service may be deleted after extended periods of inactivity. The service is recreated from Terraform and reseeded from repository evidence, so this is recoverable rather than a data-loss risk.
- Semantic ranker availability on the Free tier is not confirmed. The published throttling limits list Basic and above. The design specifies hybrid retrieval combining vector and keyword search, which is verified to work; semantic reranking is not a committed dependency. If it is adopted later, its tier availability is verified first.

## Cost rule

Target no more than $15 USD total Azure spend. Cost Management alerts are configured near $5, $10, and $15. Budgets alert rather than enforce a hard spending stop, so teardown remains the primary control.

At the Free tier the search service itself contributes no cost. The cost rule continues to apply to the rest of the runtime.

For reference, the Basic tier is billed hourly at approximately $0.10 per hour in Southeast Asia and cannot be paused; the only way to stop billing is to delete the service. That property is what makes teardown, rather than a stop action, the operative control on any billable tier.

## Consequences

**Positive**

- The keyless identity model in ADR-004 is preserved in full, with API key authentication disabled
- No recurring search cost, so the runtime can be left deployed between sessions without budget pressure
- The tier decision is grounded in verification rather than assumption
- The capability boundary between demonstration and production is stated explicitly

**Tradeoffs**

- No SLA and shared infrastructure, which is acceptable for a demonstration and is documented rather than hidden
- Promotion to a billable tier is a recreation, so it must be planned rather than toggled
- Free-tier limits must be re-checked if the corpus grows substantially beyond the v1 scope

## Decision history

| Date | State | Basis |
|---|---|---|
| 2026-09-11 | Accepted with deployment-time verification. Prefer a short-lived billable tier for the final demonstration; use Free only for early experiments | Documentation review, which was read as meaning the Free tier could not support managed identity for Entra authentication |
| 2026-09-23 | Accepted. Use Free for development and the portfolio deployment; Basic recorded as a production consideration only | Empirical validation against live Azure resources contradicted the earlier reading. The identity model, the keyless posture, and the full vector retrieval path were confirmed working on Free |

The earlier assumption is retained here rather than removed. The tier was chosen a second time on evidence rather than on a first reading of the documentation, and the correction is part of the record.

## Platform note

Findings verified on 2026-09-23 against Microsoft Learn and against live Azure resources in Southeast Asia. The Serverless Developer tier is in preview and was not offered in Southeast Asia at the time of verification, so it was not considered further for this deployment region.
