# Milestone 0 — Design Lock Checklist

Milestone 0 prevents design drift once implementation begins. The project does not add Azure services or major features during the build without recording the reason in an ADR.

## Design decisions

- [x] Objective defined
- [x] Scope boundary defined
- [x] v1 corpus limited to five controls and eight synthetic evidence files
- [x] Human-review authority separated from the AI mapping path
- [x] Deterministic citation validation required
- [x] Azure-native service set selected
- [x] Terraform selected for IaC
- [x] Remote Terraform state backend selected
- [x] GitHub Actions OIDC selected for deployment authentication
- [x] Durable Functions deferred from v1
- [x] Logic Apps deferred from v1
- [x] Agent frameworks excluded from v1
- [x] Threat boundaries defined
- [x] Evaluation strategy defined before coding
- [x] Synthetic-data policy defined
- [x] GitHub repository selected as the permanent evidence source
- [x] Azure runtime selected as disposable and recreatable
- [x] Total project spend target set to ≤ $15 USD

## Before M1 implementation starts

- [x] Confirm Azure subscription available
- [x] Confirm Microsoft Foundry/Azure OpenAI model deployment access in the intended region
- [x] Confirm GitHub repository location and account
- [x] Create repo skeleton
- [x] Add the design docs to the repo
- [x] Create initial control JSON files
- [x] Create the first two evidence fixtures for the vertical slice
- [x] Choose a Python runtime version supported by the target Azure Functions hosting plan: **3.12**
- [ ] Create one project resource group for disposable Azure resources
- [x] Configure Azure Cost Management alerts at approximately $5 / $10 / $15 (commands in `infra/README.md`)
- [x] Record deployment region: **southeastasia**. Both required model families are available there on GlobalStandard.
- [ ] Record the Azure AI Search tier choice
- [x] Bootstrap the Terraform state resource group, storage account, and container (commands in `infra/README.md`)
- [x] Install Terraform and confirm `terraform init` succeeds against the remote backend
- [ ] Verify the teardown command and process before creating billable resources

## First vertical slice

The entire corpus is not created first. This path is built first:

1. One control: IA-2(1).
2. Two evidence files: `identity-access-policy.md` and `privileged-auth-config.json`.
3. Read the two evidence files directly from the repository clone.
4. Chunk them, create embeddings, and push them directly into Azure AI Search.
5. Retrieve top-k evidence.
6. Generate one structured mapping.
7. Validate citations.
8. Persist a `DRAFT`.
9. Exercise the reviewer-only transition to `ACCEPTED`.
10. Confirm telemetry does not contain raw evidence.
11. Delete the project resource group and confirm the disposable runtime is gone.

Once that works, expand to the remaining controls, evidence, and adversarial fixtures.

## Change-control rule

Before adding a service such as Durable Functions, Logic Apps, Cosmos DB, an agent framework, or a frontend, answer:

> What concrete problem exists in the current architecture that this component solves more cleanly than the existing design?

If that cannot be answered clearly, the component is not added.
