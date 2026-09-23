# Design — Azure Security Evidence Assistant

**Status:** Approved design baseline, pre-code
**Version:** v1.0 Design Lock
**Scope stance:** A deliberately narrow demonstration of governed AI architecture, not a compliance platform.

This document defines what v1 is, how authority is separated from the model, and what is deliberately not built.

## 1. Thesis

Security evidence review is a useful place for AI assistance and a poor place for AI authority.

> **The AI drafts and cites. Only a human accepts. Code enforces the difference.**

OpenAI models hosted through Microsoft Foundry/Azure, grounded by Azure AI Search, propose mappings between synthetic security evidence and a small control set. Deterministic validation verifies the structure and provenance of the response. A human reviewer is the only actor permitted to transition a mapping to `ACCEPTED`.

The design demonstrates retrieval, grounding, deterministic guardrails, least privilege, observability, evaluation, threat modeling, and human oversight.

## 2. MVP objective

The MVP is the first complete public version of the repository. It must prove one end-to-end workflow:

1. Synthetic evidence is committed under `data/evidence/` and is the permanent source of truth.
2. An ingestion script reads the repository files, chunks them, creates embeddings through a Microsoft Foundry/Azure OpenAI model endpoint, and pushes the resulting documents directly into Azure AI Search. Azure Blob Storage is not required for v1.
3. A security control is submitted for analysis.
4. Azure AI Search retrieves the most relevant evidence chunks using hybrid retrieval.
5. A Microsoft Foundry/Azure OpenAI model deployment produces a structured advisory mapping with citations, gaps, rationale, and a bounded coverage state.
6. Deterministic code validates schema, citation provenance, enum values, and state transitions.
7. The result is persisted as `DRAFT` or `NEEDS_REVIEW`.
8. An authenticated reviewer may transition a valid `DRAFT` to `ACCEPTED` or `REJECTED`.
9. Security-relevant actions and operational metrics are observable without logging raw evidence content.

## 3. Roles

| Role | Authority |
|---|---|
| Analyst | May request a control-to-evidence mapping and inspect the resulting draft. |
| Reviewer | An authenticated Entra ID principal holding the reviewer role. Only this role may accept or reject a mapping. |
| AI pipeline | An advisory system. It may retrieve, summarize, propose, and flag gaps. It may not approve compliance status or bypass the review workflow. |

## 4. Functional requirements

| ID | Requirement |
|---|---|
| FR-01 | The system shall ingest only the committed synthetic evidence corpus for v1. |
| FR-02 | Evidence shall be chunked, embedded, and indexed with stable chunk identifiers. |
| FR-03 | Mapping requests shall retrieve a bounded top-k evidence set from Azure AI Search. |
| FR-04 | Model output shall conform to a versioned structured schema. |
| FR-05 | Every cited chunk shall exist in the index and shall have appeared in that request's retrieval set. |
| FR-06 | `COVERED` or `PARTIAL` output with no valid citation shall be rejected or downgraded. |
| FR-07 | Model output may create only `DRAFT` or `NEEDS_REVIEW` workflow states. |
| FR-08 | Only the authenticated review endpoint may create `ACCEPTED` or `REJECTED`. |
| FR-09 | Every review action shall record actor, timestamp, prior state, new state, and reviewer comment. |
| FR-10 | The system shall fail closed when retrieval, generation, validation, or persistence fails. |
| FR-11 | Operational telemetry shall exclude raw evidence content and full prompt bodies by default. |
| FR-12 | The repository shall include repeatable evaluation and adversarial tests. |

## 5. Non-functional requirements

| Area | Requirement |
|---|---|
| Security | Managed Identity and Entra RBAC are preferred over stored service credentials. |
| Least privilege | Each service identity receives only the roles required for its code path. |
| Traceability | Every model-supported claim must resolve to retrieved evidence. |
| Reliability | Failure states must be explicit; the system must not silently substitute an AI answer. |
| Observability | Retrieval, validation, token use, latency, and review transitions are measurable. |
| Data minimization | Synthetic evidence only; raw document content is not written to application telemetry. |
| Reproducibility | Azure infrastructure is declared in Terraform, can be recreated from a clean environment, and is deployed without long-lived GitHub credentials. |
| Cost | The durable asset is the repository. Azure runtime resources are disposable. Target total project spend is no more than $15 USD, with cost alerts at $5 / $10 / $15 and resource-group teardown after each session. Budgets are alerts, not hard caps. |
| Maintainability | Components remain small and separable; no framework is introduced without a demonstrated need. |

## 6. Target architecture

```text
DURABLE LAYER — GitHub repository
  ├─ data/evidence/  (synthetic source files)
  ├─ data/controls/
  ├─ Terraform / code / tests / eval results
  └─ screenshots + architecture docs
          │
          │ deploy / seed when needed
          ▼
DISPOSABLE AZURE RUNTIME
Ingestion script → Foundry/OpenAI embeddings → Azure AI Search
                                             │
Analyst request → Azure Function → retrieve ─┘
                         │
                         ▼
            Foundry/OpenAI mapping model
                         │
                         ▼
             Deterministic validation
                  │                 │
                  ▼                 ▼
              DRAFT          NEEDS_REVIEW
                  │
        authenticated reviewer
                  ▼
          ACCEPTED / REJECTED
```

Telemetry: Application Insights / Azure Monitor.
State: Table Storage.
Identity: Managed Identity + Entra RBAC.
Teardown: the project resource group is deleted when the session is complete.

## 7. Azure services

| Service | v1 role | Decision |
|---|---|---|
| Azure Functions | Ingestion, mapping API, review API | Include |
| Microsoft Foundry / Azure OpenAI model endpoints | Embeddings and structured advisory mapping | Include |
| Azure AI Search | Hybrid/vector retrieval over synthetic evidence | Include; Free tier per ADR-003 |
| Blob Storage | Optional production-style ingestion extension | Deferred |
| Table Storage | Draft mappings, reviews, audit records | Include |
| Managed Identity | Service-to-service authentication | Include |
| Microsoft Entra ID / RBAC | Reviewer authentication and authorization | Include |
| Key Vault | Residual secrets only if required | Optional; secrets are not manufactured |
| Application Insights / Azure Monitor | Telemetry and validation/review events | Include |
| Terraform | Infrastructure-as-code (`azurerm` provider) | Include |
| GitHub Actions OIDC | Keyless CI/CD authentication | Include |
| Durable Functions | Long-running/fan-out orchestration | Deferred from v1 |
| Logic Apps | Notification/workflow automation | Deferred from v1 |
| Agent framework | Autonomous reasoning/tool orchestration | Out of scope |

### Cost and lifecycle rule

> The repository is the durable asset. Azure is a disposable runtime. Deploy what is needed to build or demonstrate the project, capture results, then delete the project resource group.

Target total spend is no more than $15 USD. Cost Management alerts are configured at approximately $5, $10, and $15, while recognizing that Azure budgets notify rather than enforce a hard spending stop.

Azure AI Search runs on the Free tier for development and for the portfolio deployment. The Free tier was verified to support system-assigned managed identity, Microsoft Entra RBAC with API key authentication disabled, and the vector retrieval path the design requires, at no recurring cost. Basic is a production consideration only, for workloads requiring increased capacity, SLA coverage, or enterprise scale; it is not required by this architecture. Moving from Free to a billable tier is a recreation rather than an in-place tier change, so it forces resource replacement and an index rebuild. See ADR-003 for the validation evidence and the accepted Free-tier limitations.

## 8. Core data model

**Control**
`control_id`, `title`, `requirement_summary`, `evidence_hints[]`

**Evidence chunk**
`chunk_id`, `document_id`, `document_name`, `section`, `content`, `content_hash`, vector field

**Model mapping proposal**
`mapping_id`, `control_id`, `coverage` (`COVERED` | `PARTIAL` | `MISSING` | `NEEDS_REVIEW`), `evidence_citations[]`, `gaps[]`, `rationale`, `model_confidence` (telemetry/advisory only; never authoritative), `prompt_version`, `model_deployment`

**Review state**
`DRAFT`, `NEEDS_REVIEW`, `ACCEPTED`, `REJECTED`

## 9. Deterministic validation chain

Validation runs in order and fails closed.

1. Parse the structured response against the versioned schema.
2. Verify the requested control exists.
3. Verify each cited `chunk_id` exists.
4. Verify each cited `chunk_id` was present in the exact retrieval set supplied to the model.
5. Enforce coverage enum and field bounds.
6. Reject contradictory states, including `COVERED`/`PARTIAL` without valid citations.
7. Apply deterministic evidence-sufficiency rules where defined.
8. Persist only `DRAFT` or `NEEDS_REVIEW` from the AI path.
9. Assert in unit and integration tests that `ACCEPTED` is unreachable from the mapping path.

Model self-reported confidence may be logged or displayed as advisory context. It is not treated as calibrated truth and cannot authorize a workflow transition.

## 10. Trust boundaries

- **TB-1** Client ↔ API: caller input is untrusted.
- **TB-2** Application ↔ model output: model responses are untrusted until validated.
- **TB-3** Evidence ↔ prompt: retrieved document text is untrusted data and may contain indirect prompt injection.
- **TB-4** AI pipeline ↔ human authority: the model may propose; only an authenticated reviewer may accept.
- **TB-5** Application ↔ telemetry: observability must not become an accidental data-exfiltration path.

See [THREAT_MODEL.md](THREAT_MODEL.md) for the detailed model.

## 11. Logging and observability

Preferred telemetry fields: `request_id`, `mapping_id`, `control_id`, `retrieved_chunk_count`, `retrieval_latency_ms`, `generation_latency_ms`, `validation_status`, `validation_failure_category`, `model_deployment`, token usage, estimated cost, review state transition.

Raw evidence bodies, full prompts, secrets, tokens, and full model rationale are not logged by default.

## 12. Deliberate scope boundary

The repository does not contain a questionnaire engine, evidence-pack generation, customer onboarding, multi-tenant architecture, proprietary compliance scoring or maturity models, auditor/client portals, commercial workflow automation, a large control library, a production customer data model, or a turnkey compliance product.

The repository demonstrates an architecture pattern and engineering judgment. Productization is intentionally a separate exercise.

## 13. v1 corpus boundary

v1 uses five controls from a small NIST SP 800-53 Rev. 5 family subset, eight synthetic evidence documents, a small golden evaluation set, and 10–15 adversarial cases. See [CONTROL_EVIDENCE_PLAN.md](CONTROL_EVIDENCE_PLAN.md).

## 14. Repository structure

```text
azure-security-evidence-assistant/
├── README.md
├── docs/
│   ├── DESIGN.md
│   ├── THREAT_MODEL.md
│   ├── EVALUATION_PLAN.md
│   ├── DATA_STATEMENT.md
│   ├── CONTROL_EVIDENCE_PLAN.md
│   ├── MILESTONE_0_CHECKLIST.md
│   └── adr/
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── providers.tf
│   ├── outputs.tf
│   └── modules/
├── data/
│   ├── controls/
│   └── evidence/
├── src/
│   ├── ingest/
│   ├── mapping/
│   ├── validation/
│   ├── review/
│   └── shared/
├── evals/
│   ├── golden/
│   ├── adversarial/
│   └── results/
├── tests/
├── schemas/
├── prompts/
└── .github/workflows/
```

## 15. Milestones

| Milestone | Exit condition |
|---|---|
| M0 — Design lock | The design set is approved and the control/evidence plan is fixed. |
| M1 — Infrastructure skeleton | Terraform deploys the required Azure resources into a remote-state backend; Managed Identity and RBAC are verified; the GitHub OIDC deployment path is proven. |
| M2 — Ingest and retrieval | Synthetic evidence is chunked, embedded, pushed into Azure AI Search, and retrievable with stable citations. |
| M3 — Mapping and validation | One end-to-end mapping request produces a validated `DRAFT` or `NEEDS_REVIEW` record. `ACCEPTED` is provably unreachable from this path. |
| M4 — Review and evaluation | Reviewer authorization, state transitions, audit records, golden tests, and adversarial tests are operational. |
| M5 — Polish | README, architecture diagrams, evaluation results, cost results, case study, and demo media are complete. |

## 16. Definition of done for v1

- Infrastructure can be reproduced from Terraform.
- One thin vertical slice works end to end before the corpus is expanded.
- Every surviving citation resolves to retrieved evidence.
- No AI code path can create `ACCEPTED`.
- Missing evidence is measured explicitly.
- Adversarial evidence cannot bypass deterministic validation or the human gate.
- Keyless authentication is used wherever the selected Azure services support it.
- Actual test metrics and actual cost are published rather than described with adjectives.
- The project can be torn down to zero intended Azure runtime resources and later recreated from Terraform and repository data.
- A reader can understand the thesis, architecture, boundaries, and results from the README in roughly two minutes.

## 17. Design principle

> Architect once, then ship vertically. An Azure service is added only when it solves a concrete problem the current design does not solve cleanly.
