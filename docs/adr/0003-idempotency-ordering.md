# ADR-0003: Provider-scoped idempotency and per-payment ordering

- **Status:** Proposed
- **Date:** 2026-11-19

## Context

All providers deliver at least once or retry notifications, and ordering is not guaranteed. Andina changes `notificacion_id` on every retry; its documented business event identity is `transaccion.id` plus `transaccion.estado`. Salesforce exposes unique `Payment_Key__c` as an upsert external ID. FR4 requires one payment record in business terms, and FR5 prohibits a late event from replacing a later state.

## Options considered

### Option 1 — Deduplicate by provider delivery/event ID only

- Pros: simple for providers with a stable retry ID (Quetzal `id`, Austral `eventId`).
- Cons: fails for Andina retries because `notificacion_id` changes; event IDs alone do not identify one payment across state changes.

### Option 2 — Separate event identity from payment identity, persist both, and serialize per payment

- Pros: suppresses repeated provider business events while allowing a payment to progress through states; supports Salesforce upsert and stale-event checks; provides searchable event history/status.
- Cons: requires durable relational state and per-key processing; timestamp conflicts require quarantine/operations resolution; source identifier uniqueness assumptions must be validated.

## Decision

Choose Option 2. Maintain a provider-event key for delivery/business-event deduplication: Quetzal `id`, Andina `transaccion.id + estado`, Austral `eventId`. Maintain a separate stable Salesforce payment key: `<country>:<provider>:<SHA-256(provider transaction/payment ID)>`. Enforce uniqueness in Azure SQL and use this value for Salesforce `Payment_Key__c` upsert.

Store every accepted business-state event and the latest provider state with its source state-change timestamp. Serialize Salesforce work per payment key and preserve known transitions in timestamp order; do not coalesce a known Captured-to-Refunded transition. Reject an older state from overwriting a newer Salesforce state, and route it for reconciliation. Quarantine conflicting states with equal timestamps. Only one transition per payment key may be in flight. Keep replay tied to original event and payment keys.

## Consequences

- **Positive:** retries do not create duplicate payment rows; state transitions remain associated with one payment; delayed notifications cannot overwrite a newer state when timestamps are comparable; operations can search event and payment identifiers.
- **Negative:** ordering depends on provider timestamps; equal timestamps cannot be resolved from supplied documentation and require manual review; Salesforce automation behavior for initial Refunded or late transitions requires confirmation; key hashing is not reversible and requires storing the provider transaction ID separately for lookup.
- **Risks and mitigations:** confirm identifier uniqueness/scoping with providers; retain the provider transaction ID in the protected status store; test repeated, late, and equal-timestamp events; monitor quarantine volume and define an audited operator resolution procedure. Confirm with Salesforce how missed/out-of-order historical transitions affect policy automation.

