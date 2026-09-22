# ADR-002 — Defer Durable Functions from v1

**Status:** Accepted

## Context

Durable Functions could provide fan-out, checkpoints, retries, and long-running orchestration. The v1 corpus contains only five controls, and the mapping operation is small enough to execute through ordinary Azure Functions without a meaningful orchestration burden.

## Decision

Durable Functions are not used in v1. Standard Azure Functions handle ingestion, mapping, and review. Durable Functions are revisited only if later requirements introduce meaningful long-running work, high control-set fan-out, resumability, or multi-stage asynchronous workflows.

## Rationale

Adding an Azure service solely to display familiarity is weaker architecture than demonstrating that the service was evaluated and deliberately rejected because the workload did not justify its complexity.

## Revisit triggers

- Mapping runs become long-running
- Control-set size creates material parallel fan-out
- Checkpoint and resume becomes a user requirement
- Retry coordination becomes difficult in ordinary Functions
- Workflow history becomes operationally valuable
