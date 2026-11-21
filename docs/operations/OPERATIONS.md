# Payment notification operations

## Service objectives and indicators

Report each indicator separately for Mexico (MX), Colombia (CO), and Chile (CL). The freshness objectives come directly from NFR2. The service objective is measured over distinct accepted payment business keys so provider retries and duplicate deliveries do not inflate the result.

| SLI | Measurement | SLO |
|---|---|---|
| Salesforce freshness | Elapsed time from the provider notification's first receipt to the successful Salesforce payment upsert, per accepted payment business key. | At least 95% within 5 minutes and at least 99.5% within 1 hour. |
| Accepted-notification durability | Count each `2xx`-accepted delivery as accounted only when its durable delivery record and corresponding idempotent business-event state can be found. | Zero accepted deliveries without a durable, searchable outcome (NFR3). |
| Processing status coverage | Accepted notifications with a searchable status in the operational ledger, divided by accepted notifications. | 100% searchable without raw-log search, per FR7. |

Salesforce visibility is the completion point for freshness; an HTTP acknowledgement alone does not satisfy that SLI. A `2xx` is returned only after the durable acceptance boundary described in A-04. Report pending, recorded, failed, dead-lettered, and replay states separately so that a backlog is visible rather than treated as successful completion.

## Traceability and data handling

Generate a Meridian correlation ID for each HTTP delivery. Propagate it through the Mule intake, durable delivery/status records, canonical event and Service Bus metadata, Salesforce request context, and telemetry. Relate provider retries through their stable provider business-event key while retaining separate delivery attempts. This is the proposed propagation in A-20; validate the Mule exporter and context propagation in the target platform (A-14).

Use the scenario's existing Azure Monitor, Application Insights, and Log Analytics services. Emit structured events and metrics by country, provider, status, and processing stage. Measure accepted/recorded/failed counts, retry rate, oldest pending work, queue age, dead-letter depth, Salesforce response class, API-budget use, and per-country freshness. Exact exporter configuration is not specified.

Logs and traces may include safe provider/country identifiers, correlation ID, canonical business-event key, timestamps, attempt number, status, and a sanitized error code. Never log raw webhook bodies, payer name, national ID, email, payment token, webhook signature/secret, Salesforce credentials, or access tokens. Do not expose these fields through the operations API.

Operations searches through the internal API published by API Manager and authenticated with IdP OAuth 2.0. Apply separate least-privilege read and replay permissions. Search by provider plus provider event ID, provider transaction/payment ID, or correlation ID; return status, received time, attempt count, sanitized last error, Salesforce result, and DLQ/replay state from the SQL status index. Do not require raw-log access. Exact role names and assignment process remain open in A-18.

## Alert proposals

The following thresholds are the proposal in `SOLUTION_DESIGN.md`; they are operational defaults, not measured production baselines. Route actionable pages to the Payments Integration on-call role. Exact pager aliases, escalation policy, and support schedule are not supplied (A-30).

| Condition | Proposed threshold | Response |
|---|---|---|
| Oldest pending outbox item | More than 1 minute | Check publisher health, broker acknowledgements, and pending age by country. |
| Queue age | More than 3 minutes | Check consumer health, Salesforce responses, and capacity against the freshness SLO. |
| Dead-letter queue | Any depth above zero or new DLQ growth | Identify country/error class; stop repeated permanent failures and preserve messages for corrected replay. |
| Salesforce API allocation | More than 70% of this integration's 150,000-call rolling 24-hour budget | Check batch efficiency, retries, and other integration usage; pause consumption on `REQUEST_LIMIT_EXCEEDED` and retain the backlog. |
| Retry rate | More than 5% for 5 minutes | Break down by country and error class; separate transient failures from permanent validation failures. |
| Freshness / durability | SLO burn or any accepted notification without a durable searchable outcome | Page Payments Integration on-call; engage Salesforce/platform owners as the evidence requires. |

The thresholds and response proposals above must be tuned from measured traffic and the agreed on-call policy. Do not interpret them as configured Azure alert rules until alert resources and routing are approved.
