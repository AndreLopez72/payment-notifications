# ADR-0001: Asynchronous bulk integration with Salesforce

- **Status:** Proposed
- **Date:** 2026-11-19

## Context

Salesforce is the system of record, has approximately 97% monthly availability, and allows this integration up to 150,000 API calls per rolling 24 hours within a shared org-wide limit. The integration user is limited to 25 concurrent requests. Collection upsert supports up to 200 `Premium_Payment__c` records per request, and each request counts as one API call. Provider response deadlines are 5–10 seconds, while the freshness target is 95% within 5 minutes and 99.5% within 1 hour. The integration must not lose an accepted notification and must not write policy status.

## Options considered

### Option 1 — Synchronous single-record Salesforce upsert before acknowledging the provider

- Pros: straightforward request-to-record flow; immediate Salesforce result.
- Cons: Salesforce latency can reach 8 seconds for one request, close to the 5-second Andina deadline and 10-second deadlines of the others; Salesforce outages can break webhook acceptance; up to one API call per notification can consume budget and magnify shared-limit risk.

### Option 2 — Asynchronous, durable intake followed by bulk Salesforce upsert

- Pros: acknowledge after durable acceptance without waiting on Salesforce; buffer through documented 5–90 minute outages; up to 200 records per API call greatly reduces API consumption; decouples provider deadlines from Salesforce latency.
- Cons: requires durable state, an outbox/queue, consumer operations, retries, DLQ, and replay; batching adds a small wait; Salesforce data is not immediately visible after webhook response.

## Decision

Choose Option 2. Mule intake persists the validated, sanitized canonical event and its outbox entry in one Azure SQL transaction, then returns provider-compatible `2xx`. An outbox publisher sends events to Azure Service Bus. A Salesforce consumer routes calls through an internal Salesforce System API in API Manager, groups up to 200 payment rows per collection upsert, uses `allOrNone=false`, and processes individual results. The gateway requires the IdP machine-to-machine token; the Salesforce backend uses its OAuth client-credentials flow. Cap concurrency at 20 requests, below the documented 25-request maximum, and serialize updates per payment key. Do not place two transitions for the same payment key in one concurrent batch; apply subsequent transitions only after the previous result is known. Cache OAuth tokens and refresh after the relevant token-expiration response.

Quetzal partial-refund events are retained and published with the refunded amount, but Salesforce writes for partial refunds are held for reconciliation until the Salesforce team confirms a safe mapping to its documented payment status and automation. This provisional exception can delay Salesforce visibility for those payments.

On `500/502/503` and `UNABLE_TO_LOCK_ROW`, retry with exponential backoff and jitter. On `REQUEST_LIMIT_EXCEEDED`, pause consumption until usage recovers and preserve queued work. Do not retry permanent validation errors without correcting data. After the configured retry budget, persist dead-letter intent in SQL with an outbox record, publish it to the processing DLQ, and expose its status to Operations. Replay uses the same payment and business-event keys and is recorded as a new outbox action.

Capacity estimate at 120,000 notifications/day: the hard upper bound of one call per notification is 120,000 calls/day (80% of the 150,000-call integration budget). At the 40/second burst, a 2-second batch linger yields about 80 records/request, or approximately 450 calls for the 36,000-event 15-minute burst; full 200-record batches would need 180 calls. Salesforce collection-upsert p95 is about 4 seconds. This is a sizing estimate, not an SLA guarantee; load testing and backlog-drain validation are required.

## Consequences

- **Positive:** provider acknowledgment is isolated from Salesforce availability; batching protects the API budget; durable queueing supports freshness and no-loss requirements; policy status is not written.
- **Negative:** Salesforce visibility is eventual; the integration now operates SQL, an outbox publisher, Service Bus, and a consumer; bad source data requires operational remediation rather than blind retry.
- **Risks and mitigations:** SQL and broker capacity/availability must be validated in IaC and load tests. The org-wide Salesforce limit is shared, so alert before the integration budget is exhausted and coordinate with the Salesforce team. Outbox dispatch and consumer replay must be idempotent using provider event keys and Salesforce `Payment_Key__c` upsert.

