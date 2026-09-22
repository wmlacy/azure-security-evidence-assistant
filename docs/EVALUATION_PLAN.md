# Evaluation Plan — Azure Security Evidence Assistant

Metrics, golden tests, adversarial tests, and cost protocol.

## 1. Purpose

Evaluation must show whether the system retrieves the right evidence, avoids false coverage, preserves citation provenance, withstands selected adversarial inputs, and fails safely.

The repository publishes numbers rather than claims such as "highly accurate" or "secure."

## 2. Evaluation sets

### Golden set

A small labeled set covering all five controls and the synthetic evidence corpus. Each case records:

- expected relevant document and chunk IDs
- expected coverage class
- expected missing evidence, if any
- whether a positive-coverage answer is supportable

Target initial size: 20–30 mapping expectations.

### Adversarial set

Target initial size: 10–15 selected cases across these categories:

- direct instruction embedded in evidence
- role-play or system-message imitation
- hidden-looking delimiter tricks
- Unicode and homoglyph instruction variants
- fabrication bait with zero relevant evidence
- plausible but nonexistent citation IDs
- malformed structured output
- hostile but schema-valid API payload
- oversized evidence or document edge case
- contradictory evidence

## 3. Core metrics

**Retrieval**
- Recall@K: did the expected relevant evidence appear in the retrieved set?
- Precision@K: how much of the retrieved set was actually relevant?

**Mapping quality**
- coverage accuracy by class
- missing-evidence recall
- false-coverage rate

> False coverage and missed gaps matter more than a flattering aggregate accuracy figure.

**Grounding**
- pre-validation citation validity rate
- post-validation citation validity rate
- fabricated-citation catch rate

Post-validation surviving citations are 100% resolvable by construction. The informative number is how often the guardrail had to reject or correct model output.

**Reliability**
- structured-output validity rate
- fail-closed rate for forced error scenarios
- p50/p95 retrieval latency
- p50/p95 generation latency

**Cost**
- input and output tokens per mapping
- embedding volume for corpus creation
- estimated and actual cost per full evaluation run
- actual cost per deployment session
- cumulative project spend against the $15 USD target
- teardown verification: intended Azure runtime resources return to zero after the session

## 4. Security-oriented acceptance criteria

v1 is acceptable when:

1. No fabricated citation survives deterministic validation.
2. No AI code path can create `ACCEPTED`.
3. Unauthorized review transitions are denied.
4. `COVERED` and `PARTIAL` cannot survive without valid retrieved evidence.
5. All deliberately absent-evidence cases are surfaced as `MISSING` or `NEEDS_REVIEW`, or any misses are documented honestly before release.
6. Prompt-injection cases do not bypass deterministic validation or the human approval boundary.
7. Telemetry tests confirm raw evidence bodies are not emitted through the normal logging path.

A claim that the model is "100% prompt-injection resistant" is intentionally not required. The evaluation measures behavior without implying a general security guarantee.

## 5. Results table

| Metric | Result | Target / interpretation |
|---|---|---|
| Recall@5 | TBD | Report by control and overall |
| Precision@5 | TBD | Contextual; not optimized at the cost of recall |
| Missing-evidence recall | TBD | Prefer ≥ 0.90 on the small golden set |
| False-coverage rate | TBD | Lower is better; reported honestly |
| Pre-validation citation validity | TBD | Shows model behavior |
| Post-validation citation validity | TBD | 100% for surviving citations by construction |
| Fabricated-citation catch rate | TBD | 100% for known test cases |
| Unauthorized acceptance blocked | TBD | 100% |
| Structured-output validity | TBD | Reported rather than hidden |
| p95 mapping latency | TBD | Operational metric |
| Cost per full eval run | TBD | Actual value published |
| Cumulative Azure project spend | TBD | Target ≤ $15 total |
| Disposable teardown verified | TBD | Yes after each session |

## 6. Failure injection

Tests deliberately simulate:

- Azure AI Search timeout or error
- Azure OpenAI timeout or rate limit
- malformed model response
- empty retrieval set
- Table Storage persistence failure
- invalid reviewer identity or role

Expected behavior is an explicit error or `NEEDS_REVIEW`, never an invented fallback assessment.

## 7. Versioning

Each evaluation result records the git commit SHA, prompt version, schema version, model deployment and model version where available, retrieval configuration and top-k, and date of run. This makes changes attributable rather than anecdotal.

## 8. Cost protocol

The repository is the permanent artifact; Azure is used only when implementation, evaluation, or demonstration requires it. For each meaningful cloud session, the deployed SKUs, approximate start and end time, token usage, and observed Azure cost are recorded.

Cost alerts are configured at approximately $5, $10, and $15. These are monitoring thresholds rather than a guaranteed hard stop. The primary cost-control mechanism is keeping project resources in one disposable resource group and deleting it after the session.
