# Data Statement — Azure Security Evidence Assistant

Synthetic-data and minimization policy.

## 1. Data policy

This repository uses synthetic demonstration data only.

No customer documents, employer documents, military or DoD artifacts, production configuration exports, real vulnerability reports, personal records, credentials, or proprietary compliance evidence may be committed to the repository or loaded into the temporary Azure demo environment.

## 2. Synthetic evidence

The v1 corpus is intentionally small, lives under `data/evidence/`, and contains eight fictional artifacts designed to resemble common security evidence categories while containing no real organizational data.

Synthetic artifacts use invented company names, users and email addresses, hostnames and tenant identifiers, IP addresses reserved for documentation where applicable, dates and ticket numbers, configuration values, and incident and vulnerability details.

Every evidence file contains a header or metadata field indicating that it is synthetic.

## 3. Control-source policy

The control subset is based on a small set of NIST SP 800-53 Revision 5 control identifiers and titles. NIST publications are U.S. Government works and are suitable for this public demonstration. The repository attributes the source and identifies the version used.

Proprietary control libraries and copyrighted framework text from paid or licensed compliance content are not reproduced.

For project-specific evaluation, short `requirement_summary` fields are written in original wording so that expected evidence is unambiguous.

## 4. Data minimization

Only data needed to demonstrate the architecture exists. The system does not need real PII, real secrets, real customer security posture, real audit findings, full production-scale compliance frameworks, or realistic account numbers and credentials.

## 5. Logging policy

Application telemetry may contain IDs, hashes, status values, counts, durations, model and token metadata, validation failure categories, and a reviewer identity identifier as appropriate for the demo audit trail.

Normal telemetry must not contain full evidence body text, full prompts, secrets or tokens, or raw model responses unless explicitly quarantined in a controlled development-only path.

## 6. Repository tripwire

CI includes a lightweight synthetic-data tripwire that searches for obvious accidental secret and PII patterns. This is a guardrail, not a claim of complete DLP coverage.

Suggested checks include common cloud secret formats, private-key headers, obvious access-token patterns, non-documentation public IPv4 values where unexpected, and realistic SSN-like patterns.

False positives are handled explicitly rather than by weakening the check globally.

## 7. Scope statement

> All evidence in this repository is synthetic and exists only to demonstrate architecture, retrieval, validation, and human-review patterns. The project is not trained or evaluated on customer security data, and its evaluation results should not be interpreted as production compliance performance.

## 8. Source of truth and cloud lifecycle

The repository copy of each synthetic evidence file is authoritative. Azure runtime indexes are temporary derivative data that can be rebuilt from the repository. Deleting the Azure resource group does not destroy the source data or evaluation fixtures.
