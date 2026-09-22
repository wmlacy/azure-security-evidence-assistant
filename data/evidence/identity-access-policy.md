---
document_id: E-01
document_name: identity-access-policy.md
synthetic: true
synthetic_notice: "Fictional demonstration artifact. Meridian Freight Systems is an invented organization. No real policy, person, system, or tenant is represented."
evidence_type: policy
supports_controls: ["AC-2", "IA-2(1)"]
version: v1
effective_date: 2026-01-15
owner: Director of Information Security
---

# Meridian Freight Systems — Identity and Access Management Policy

**Document ID:** MFS-POL-004
**Classification:** Internal
**Review cycle:** Annual

## 1. Purpose

This policy defines how accounts at Meridian Freight Systems are authorized, issued, maintained, and removed, and the authentication requirements that apply to them. It applies to all corporate identity platforms, including the `meridianfreight.example` cloud identity tenant.

## 2. Scope

This policy covers standard user accounts, privileged administrative accounts, service accounts, and vendor accounts. It does not cover customer-facing portal accounts, which are governed by MFS-POL-011.

## 3. Account authorization

All accounts must be authorized before creation. Account requests are submitted through the IT service desk and require documented approval from the requesting employee's manager. Privileged account requests additionally require approval from the Director of Information Security.

Each account must have a named owner. Shared accounts are prohibited except for approved break-glass accounts, which are documented in the emergency access register.

## 4. Account lifecycle

Accounts follow a defined lifecycle:

- **Creation** — provisioned only after documented approval, with entitlements limited to the approved role.
- **Modification** — entitlement changes follow the same approval path as creation.
- **Separation** — accounts are disabled within one business day of a confirmed separation notice from Human Resources and deleted after 30 days.
- **Dormancy** — accounts with no interactive sign-in for 90 consecutive days are flagged for review.

## 5. Periodic account review

Account entitlements are reviewed quarterly. Each review covers account ownership, account type, current status, and whether the assigned entitlements remain appropriate. System owners are responsible for confirming or revoking entitlements for accounts in their scope.

Reviews that identify accounts requiring action must record a disposition for each such account. Completed reviews are retained for two years.

## 6. Authentication requirements

### 6.1 Standard accounts

Standard user accounts authenticate with a password meeting the complexity requirements in MFS-STD-002, plus a second factor for access from outside the corporate network.

### 6.2 Privileged accounts

Multi-factor authentication is required for all privileged accounts without exception, on every sign-in, regardless of network location. Privileged roles in scope include Global Administrator, Security Administrator, Exchange Administrator, User Administrator, and Privileged Role Administrator.

Phishing-resistant authentication methods are required for privileged accounts. SMS and voice call methods are not permitted as a second factor for privileged sign-in.

### 6.3 Break-glass accounts

Two emergency access accounts are maintained. These accounts are excluded from conditional access policies by design and are protected by physically secured credentials, monitored for any sign-in activity, and tested semi-annually.

## 7. Service accounts

Service accounts must be non-interactive, must not be assigned privileged administrative roles, and must use managed or federated credentials where the platform supports them.

## 8. Enforcement

Deviations from this policy require a documented exception approved by the Director of Information Security, with a defined expiry date and compensating controls.

## 9. Revision history

| Version | Date | Change |
|---|---|---|
| v1 | 2026-01-15 | Initial issue |
