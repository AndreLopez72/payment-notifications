# Assumptions and open decisions

> Each entry records a design choice not fully specified by the assessment. Provisional choices must be confirmed by the owner listed before production.

## A-01 — Integration runtime, store, and messaging

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; `docs/adr/0002-stack-and-state-store.md`; Part C IaC.
- **Question:** Should the target use Mule 4 on the enterprise integration platform with Azure SQL and Service Bus?
- **Context:** The assessment names Mule 4 as the reference stack and Azure as the cloud, but does not select a database or broker. The employer stack also lists Java, Functions, Container Apps, App Service, AKS, Cosmos DB, and RabbitMQ.
- **Options:** (1) Mule 4 + relational store + Service Bus — uses the reference platform and supports transactions/unique constraints; adds connectors and operational dependencies. (2) Java/Azure compute + non-relational store or RabbitMQ — may fit other company services; adds a second runtime or broker choice and needs a separate justification.
- **Provisional assumption used:** Mule 4 hosts all application flows; Azure SQL stores state; Service Bus distributes canonical events. No separate Azure application compute is provisioned.
- **Impact if incorrect:** Connector, identity, availability, capacity, IaC, and cost design may need revision.
- **Who should answer:** Payments Integration platform owner and Azure platform team.

## A-02 — Mule-to-Azure identity

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; `docs/adr/0002-stack-and-state-store.md`; `infra/`.
- **Question:** Can the existing integration/API Manager platform use managed identity or an approved federated workload identity to access Azure SQL, Service Bus, and Key Vault?
- **Context:** NFR6 requires managed identities for Azure resources and prohibits secrets in code/configuration. The integration platform's Azure identity capability is not described.
- **Options:** (1) Supported managed/federated identity — avoids stored Azure credentials and allows least privilege; depends on platform support. (2) Move the Azure-connected worker to an Azure runtime with managed identity — satisfies the identity direction; changes deployment placement and runtime topology.
- **Provisional assumption used:** Mule can use a supported non-secret identity mechanism. No stored Azure credential is allowed.
- **Impact if incorrect:** The selected runtime placement cannot satisfy NFR6 and must change before implementation.
- **Who should answer:** Integration platform owner and Azure identity/platform team.

## A-03 — Payment key derivation and provider identifier uniqueness

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; `docs/adr/0003-idempotency-ordering.md`; Part B mapping.
- **Question:** Are provider transaction/payment identifiers unique within their provider and country for the full payment lifecycle?
- **Context:** Salesforce requires a unique `Payment_Key__c` of at most 80 characters; source ID length and uniqueness scope are not specified.
- **Options:** (1) Scoped raw provider ID — readable and simple; may exceed the field length or collide across scopes. (2) Country/provider plus SHA-256 digest — bounded and scoped; not reversible and requires retaining the original identifier for lookup.
- **Provisional assumption used:** Use `<country>:<provider>:<SHA-256(providerTransactionId)>` as `Payment_Key__c` and retain the original provider ID in the restricted status store.
- **Impact if incorrect:** Distinct payments could collide or one payment could create multiple Salesforce records; identifiers longer than Salesforce fields may fail.
- **Who should answer:** Provider integration contacts and Salesforce team.

## A-04 — Durable acceptance and asynchronous Salesforce processing

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; `docs/adr/0001-salesforce-integration.md`.
- **Question:** Is a committed Azure SQL inbox/outbox transaction an acceptable durability boundary for returning provider `2xx`?
- **Context:** NFR3 defines acceptance as `2xx`; provider timeouts are 5–10 seconds; Salesforce availability is about 97%.
- **Options:** (1) Acknowledge after SQL commit and process Salesforce asynchronously — decouples provider delivery from Salesforce; depends on SQL durability and recovery. (2) Acknowledge only after Salesforce — simpler visibility semantics; risks provider timeout and does not tolerate Salesforce outages for intake.
- **Provisional assumption used:** Return `2xx` only after the validated event and outbox row commit; Salesforce updates happen asynchronously.
- **Impact if incorrect:** Accepted notifications may not meet durability or provider response-time expectations.
- **Who should answer:** Payments Integration product owner and platform/Salesforce teams.

## A-05 — Ordering, late events, and Salesforce transition side effects

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; `docs/adr/0003-idempotency-ordering.md`.
- **Question:** Does Salesforce automation produce the required result if a payment's earlier transition arrives after its later transition has already been applied?
- **Context:** Providers do not guarantee ordering. Salesforce automation describes Captured and Captured-to-Refunded transitions; no ordering watermark or maximum lateness is documented.
- **Options:** (1) Apply each known transition in timestamp order and quarantine older events after a later state is committed — preserves known transitions; a late event may arrive after the later state was applied. (2) Wait for a provider-defined lateness window or query provider state — could improve ordering certainty; no such bound or read API is specified and waiting may conflict with freshness.
- **Provisional assumption used:** Persist each distinct business-state event; process known pending events in timestamp order per payment key without coalescing them. Never regress Salesforce with a stale event; mark stale events for reconciliation. Equal-timestamp conflicts are quarantined. This does not claim the Salesforce automation side effect is correct in every late-arrival case.
- **Impact if incorrect:** Salesforce may miss a transition-triggered policy recalculation or temporarily show a stale state.
- **Who should answer:** Salesforce policy-core owner and provider contacts.

## A-06 — Partial refund behavior

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; canonical event contract; Salesforce data model/automation.
- **Question:** How should a partial Quetzal refund affect `Premium_Payment__c` and the policy balance?
- **Context:** Quetzal distinguishes `amount_refunded` and allows partial refunds. Salesforce documents only `Captured` and `Refunded` and describes automation for Captured-to-Refunded; partial-refund behavior is not specified.
- **Options:** (1) Treat any partial refund as `Refunded` — fits the current enum; risks representing a partial amount as a full refund. (2) Extend Salesforce model/automation to represent partial refund amount/state — more accurate; requires Salesforce team change. (3) Hold partial-refund Salesforce work for reconciliation — avoids a potentially wrong policy update; delays FR3/NFR2 for those payments.
- **Provisional assumption used:** Persist and publish the canonical refund event with `refundedAmount`; when refunded amount is less than original amount, hold the Salesforce update for reconciliation until the Salesforce mapping is agreed.
- **Impact if incorrect:** Incorrect overdue balance, policy reinstatement/suspension, or delayed payment visibility.
- **Who should answer:** Salesforce policy-core owner and Payments product owner.

## A-07 — Freshness SLO feasibility during Salesforce outages

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; `docs/adr/0001-salesforce-integration.md`; operations SLOs.
- **Question:** Can the 95%/5-minute and 99.5%/1-hour targets be met given the documented Salesforce availability and outage windows?
- **Context:** Salesforce is approximately 97% available and outages are reported as 5–90 minutes. Traffic distribution during outages and backlog recovery capacity are not supplied.
- **Options:** (1) Keep the targets and increase recovery capacity — may meet them if outage-affected volume remains within the error budget; requires measured outage/load data. (2) Change the target or Salesforce availability commitment — aligns SLO to dependency behavior; requires business/Salesforce approval.
- **Provisional assumption used:** Preserve the stated targets as objectives, retain accepted messages durably, and do not claim they are proven by the nominal latency estimate. Validate with outage and drain tests.
- **Impact if incorrect:** The proposed design could miss NFR2 despite successful buffering.
- **Who should answer:** Product/SLO owner and Salesforce team.

## A-08 — FR7 scope for unauthenticated or invalid deliveries

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; operations status API.
- **Question:** Must FR7 lookup include requests rejected for invalid signatures or malformed payloads, or only authenticated provider notifications?
- **Context:** FR7 says any notification can be found by provider identifiers. The current flow rejects invalid signatures without recording them; storing untrusted request metadata has privacy and abuse implications.
- **Options:** (1) Persist minimal sanitized rejection metadata — improves diagnostics; requires safe identifier parsing, retention, and abuse controls. (2) Exclude unauthenticated requests from FR7 — avoids persisting untrusted data; limits operator visibility.
- **Provisional assumption used:** FR7 covers authenticated notifications only; invalid-signature requests are rejected and not added to the payment status ledger.
- **Impact if incorrect:** Operations may be unable to find some provider delivery attempts.
- **Who should answer:** Payments product owner and security/privacy owner.

## A-09 — Source identifier maximum lengths

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; Salesforce field mapping; canonical schema.
- **Question:** Do provider transaction, event, and notification IDs always fit the Salesforce Text(80) fields?
- **Context:** Salesforce fields are limited to 80 characters, while provider specs declare IDs as strings without maximum lengths.
- **Options:** (1) Validate and reject/hold values above 80 — preserves field semantics; requires exception handling. (2) Extend Salesforce fields or persist full IDs externally and map a surrogate — avoids truncation; requires Salesforce/model agreement and may affect operators.
- **Provisional assumption used:** No truncation is allowed. Confirm provider limits before production; unresolved overlength values are held from Salesforce writes and surfaced as data errors.
- **Impact if incorrect:** Valid provider events may fail Salesforce validation and miss freshness targets.
- **Who should answer:** Provider contacts and Salesforce team.

## A-10 — Retry, batching, and concurrency values

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; `docs/adr/0001-salesforce-integration.md`; Part C/D.
- **Question:** Are the proposed batch linger, concurrency cap, and retry schedule acceptable under observed load and the shared Salesforce API budget?
- **Context:** Salesforce documents batches up to 200, max 25 concurrent requests, and error-specific retry guidance, but not application batch timing or retry limits.
- **Options:** (1) Use the current conservative proposed values — low concurrency and bounded backoff; may increase queue age. (2) Tune from load/production data — better utilization; requires representative tests and Salesforce coordination.
- **Provisional assumption used:** Up to 200 records/request, 2-second maximum linger, maximum 20 concurrent requests, exponential retry with jitter starting at 1 second, capped at 5 minutes and 12 hours before dead-letter.
- **Impact if incorrect:** API budget exhaustion, provider/Salesforce backlog, or missed freshness SLO.
- **Who should answer:** Payments Integration operations owner and Salesforce team.

## A-11 — Canonical amount representation

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; Part B event schema and Salesforce mapper.
- **Question:** Is major-unit decimal with two fractional digits the canonical amount representation for all currencies?
- **Context:** Quetzal sends minor units, Andina sends major-unit decimal strings with two decimals, Austral sends integer CLP, and Salesforce uses Currency(16,2).
- **Options:** (1) Normalize to major-unit decimal with two fractional digits — maps directly to Salesforce; needs exact decimal parsing and currency-specific conversion. (2) Use integer minor units — avoids floating-point rounding; CLP has no minor unit and currency scale must be represented.
- **Provisional assumption used:** Use decimal strings in major units; divide Quetzal values by 100, parse Andina decimals, and represent CLP integer values with `.00` for Salesforce.
- **Impact if incorrect:** Rounding or amount discrepancies can affect payment records and policy calculations.
- **Who should answer:** Payments domain owner and Salesforce team.

## A-12 — HTTP responses for invalid inputs and duplicate deliveries

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; Part B OpenAPI/implementation.
- **Question:** Are the proposed response codes for invalid signatures, invalid payloads, persistence failure, and duplicates accepted by each provider contract?
- **Context:** Provider specs define success codes and retry behavior but do not specify exact codes for every invalid request.
- **Options:** (1) 4xx for invalid requests, 5xx for persistence failure, 2xx for a durably recognized duplicate — avoids retrying permanent errors and permits transient recovery; must fit provider handling. (2) Use different statuses per provider — could better match provider behavior; adds adapter-specific response logic.
- **Provisional assumption used:** Return 204 for valid new/duplicate deliveries after durable commit; return 4xx for invalid signature/payload and 5xx for durable-store failure.
- **Impact if incorrect:** Providers may retry non-retryable errors or stop retrying a notification that was not durably accepted.
- **Who should answer:** Provider integration contacts.

## A-13 — Policy reference correction workflow

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; operations replay process.
- **Question:** Who may correct an invalid policy reference, and how is the corrected reference verified before replay?
- **Context:** Salesforce returns a permanent 400 for an unknown policy external ID; Andina v2.3 may send the payer-entered reference verbatim. No correction workflow is specified.
- **Options:** (1) Operations corrects a stored canonical record after independent verification — enables recovery; requires audit and authorization controls. (2) Request provider/checkout correction and receive a new webhook — retains source ownership; recovery timing is outside Meridian's control.
- **Provisional assumption used:** Do not guess or silently normalize beyond documented uppercase/format validation. Hold the sanitized record for authorized manual correction and replay only after verification.
- **Impact if incorrect:** Paid premiums may remain unrecorded or a payment may be linked to the wrong policy.
- **Who should answer:** Operations lead and Salesforce policy-core owner.

## A-14 — Observability platform

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; Part C/D monitoring.
- **Question:** Is Dynatrace required in the actual assessment environment in addition to the Azure monitoring services stated in the scenario?
- **Context:** The assessment names Azure Monitor, Application Insights, and Log Analytics as existing platform services; Dynatrace appears in separately supplied employer-stack information. The Mule-to-Azure telemetry exporter/configuration is also not described.
- **Options:** (1) Reuse the named Azure services — follows the assessment, avoids an unrequested duplicate APM platform; may differ from the employer's live standard. (2) Add or substitute Dynatrace — aligns to the employer description; requires integration, ownership, and cost decisions not in the assessment.
- **Provisional assumption used:** Use the scenario's Azure Monitor, Application Insights, and Log Analytics; do not add Dynatrace to this assessment proposal. Configure telemetry export using a platform-supported mechanism after the integration platform owner confirms it.
- **Impact if incorrect:** Operational dashboards/alerts may not match the actual team's standard platform.
- **Who should answer:** Assessment/platform owner.

## A-15 — Dead-letter destination and replay workflow

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; Part C messaging IaC; operations runbook.
- **Question:** Should exhausted Salesforce work use an application-managed DLQ fed by the SQL outbox, a native Service Bus subscription DLQ, or both?
- **Context:** The design needs durable status and safe replay. The assessment requires messaging with dead-letter configuration but does not prescribe settlement/replay mechanics.
- **Options:** (1) SQL status + outbox to a processing DLQ — keeps status/replay intent durable; adds another outbox flow. (2) Native Service Bus DLQ — uses broker delivery handling; SQL status can diverge unless reconciliation is designed. (3) Both — covers application and broker failures; adds operational complexity.
- **Provisional assumption used:** SQL remains the status source of truth; an outbox records dead-letter/replay actions, and broker DLQ is configured for delivery-level poison messages.
- **Impact if incorrect:** A message may be dead-lettered but not discoverable, or replayed without a coherent status/audit trail.
- **Who should answer:** Azure messaging owner and Payments Integration operations owner.

## A-16 — Retention and privacy approval

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; IaC data retention; operations access.
- **Question:** Is 90 days an acceptable retention period for provider identifiers, canonical events, and processing status in all three countries?
- **Context:** FR7 requires operational lookup and safe replay; NFR6 requires compliance with each country's privacy law, but no retention schedule is supplied.
- **Options:** (1) Retain for 90 days — supports investigation/replay; may exceed an approved privacy limit. (2) Use a shorter/longer country-specific period — can match policy; may complicate shared operations and replay.
- **Provisional assumption used:** Retain sanitized operational metadata for 90 days; do not retain raw webhook bodies, payer PII, payment tokens, or secrets. This is pending privacy/legal approval.
- **Impact if incorrect:** Data may be retained too long or removed before incident investigation/replay completes.
- **Who should answer:** Privacy/legal owner for each country and Operations lead.

## A-17 — Azure resource tiers and cost

- **Documents affected:** Part C `docs/infra/AZURE_SERVICES.md` and IaC.
- **Question:** Which Azure SQL and Service Bus tiers, redundancy settings, and budgets are approved for the target workload?
- **Context:** The exercise gives traffic and one-region constraints but no SKU, pricing, availability configuration, or monthly budget.
- **Options:** (1) Lower-cost tiers — reduce spend; may not meet burst, HA, or backlog-drain requirements. (2) Higher-throughput/redundant tiers — more headroom and resilience; increase cost and need a justified estimate.
- **Provisional assumption used:** No SKU or cost is asserted in this design; select after throughput, recovery, and cost validation. One Azure region serves the three countries as stated in the scenario.
- **Impact if incorrect:** Under-provisioning can miss freshness/durability objectives; over-provisioning can waste cost.
- **Who should answer:** Azure platform/FinOps owner and Payments product owner.

## A-18 — Operations API authorization

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; operations API contract and runbook.
- **Question:** Which operator roles may search notification status, correct eligible data, and request replay?
- **Context:** FR7 requires secured operational access and the scenario states that internal APIs published through API Manager require an IdP token, but it does not define authorization roles or separation of duties.
- **Options:** (1) Read-only search role plus a separate replay/correction role — limits write access; requires role lifecycle and audited approvals. (2) One operations role for search and replay — simpler to administer; grants broader privilege.
- **Provisional assumption used:** Expose the operations API through API Manager with IdP OAuth 2.0 and separate least-privilege read and replay permissions; record and audit every replay request.
- **Impact if incorrect:** Operators may gain excessive access, or incident remediation may be blocked by insufficient permissions.
- **Who should answer:** Operations lead, identity/access-management owner, and security team.

## A-19 — Canonical event contract and versioning

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; `docs/api/events/premium-payment.schema.json`; `docs/api/README.md`.
- **Question:** Is `schemaVersion` as a `major.minor` string and the proposed field set acceptable to Finance and Notifications?
- **Context:** FR2 and FR6 require a canonical event; Part B requires a versioned JSON Schema. The assessment does not define field names, required fields, event ID format, or compatibility rules.
- **Options:** (1) Version field in the event with additive optional changes within a major version — easy for consumers to inspect; requires compatibility discipline. (2) Version in schema/metadata outside the payload — keeps payload business-focused; depends on broker/schema tooling not specified.
- **Provisional assumption used:** Use `schemaVersion: "1.0"` and the fields proposed in `SOLUTION_DESIGN.md`; require those fields in the event, with `refundedAmount` present as a nullable value when no refund amount is supplied; treat additive optional fields as compatible within a major version. Requiredness is a proposal because the assessment does not define it.
- **Impact if incorrect:** Producers and consumers may interpret the same event differently or break on contract evolution.
- **Who should answer:** Payments Integration API owner and downstream Finance/Notifications owners.

## A-20 — Correlation identifier generation and propagation

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; operations instrumentation; event schema.
- **Question:** Should Meridian generate a correlation ID for each incoming delivery and propagate it in the event, database, messaging metadata, and logs?
- **Context:** NFR7 requires end-to-end traceability; provider specs do not define a common correlation header or ID.
- **Options:** (1) Generate a Meridian ID when no trusted ID is present — consistent traceability; each provider retry gets a separate delivery trace unless linked to the business event. (2) Reuse provider event ID — easier cross-reference; may be stable across retry deliveries and is not a unique delivery trace.
- **Provisional assumption used:** Generate a unique correlation ID per HTTP delivery; store it with the delivery attempt and propagate it through SQL, Service Bus metadata, Mule logs/traces, and the Salesforce call context. Link related provider retries through their business-event key.
- **Impact if incorrect:** Operations may not be able to trace one delivery or connect retries to the payment lifecycle.
- **Who should answer:** Payments Integration observability owner and API Manager team.

## A-21 — Secrets-store product

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; Part C IaC and `docs/infra/AZURE_SERVICES.md`.
- **Question:** Is Azure Key Vault the approved secrets store for provider webhook secrets and the Salesforce client secret?
- **Context:** NFR6 requires a secrets store but does not name a product; the employer technology description names Key Vault.
- **Options:** (1) Azure Key Vault — aligns with the supplied employer stack and Azure environment; requires Mule identity integration and access-policy design. (2) Existing enterprise secrets manager — may fit Mule operations; its product and Azure connectivity are not documented.
- **Provisional assumption used:** Use Azure Key Vault with least-privilege managed/federated identity from the component that manages each backend integration; never place secrets in code, payloads, logs, or plain configuration.
- **Impact if incorrect:** Secret access, identity, IaC, and operational procedures need redesign.
- **Who should answer:** Security secrets-management owner and Azure platform team.

## A-22 — API Manager mediation of Salesforce access

- **Documents affected:** `docs/design/SOLUTION_DESIGN.md`; `docs/adr/0001-salesforce-integration.md`; API Manager configuration; `pr-review/PR-214.md`.
- **Question:** Can API Manager mediate and cache Salesforce OAuth client-credentials tokens for the Salesforce System API?
- **Context:** The scenario requires no point-to-point system calls, an IdP token for internal APIs published through API Manager, and Salesforce OAuth 2.0 client credentials. It does not specify whether API Manager supports the required backend token exchange and caching. PR-214 describes a `SalesforceClient` interface as handling OAuth token caching, but does not include its implementation or establish whether calls pass through API Manager.
- **Options:** (1) Mule calls a Salesforce System API through API Manager, where gateway/backend configuration obtains and caches Salesforce credentials — centralizes API governance; requires supported token mediation and credential ownership. (2) Mule obtains and attaches Salesforce OAuth credentials when calling the System API through API Manager — keeps backend authentication in the integration; requires secure token handling in Mule and still routes the API through the gateway.
- **Provisional assumption used:** Keep the current proposal: route all Salesforce REST requests through an internal API Manager System API; require an IdP M2M token at the gateway; have API Manager mediate Salesforce OAuth client credentials, using the approved secrets store and caching the access token for its documented lifetime. This is a provisional design choice, not confirmation that the target API Manager supports the flow.
- **Impact if incorrect:** An unsupported token mediation design could block Salesforce writes; direct calls could violate the no-point-to-point rule. Confirm platform capability before implementing the Salesforce route or its credentials configuration.
- **Who should answer:** API Manager owner and Salesforce integration/security team.

## A-23 — Webhook paths and contract dialects

- **Documents affected:** `docs/api/webhooks.openapi.yaml`; `docs/api/events/premium-payment.schema.json`; `docs/api/README.md`.
- **Question:** Are the proposed webhook paths, request-field requiredness, and contract dialect versions compatible with the API Manager and provider registrations?
- **Context:** Provider specifications say the merchant configures a webhook URL, and the assessment requires OpenAPI 3.x and a JSON Schema, but none specifies endpoint paths, all required source fields, or exact dialect versions supported by the API Manager and tooling.
- **Options:** (1) Use separate provider-named paths and OpenAPI 3.1.0 / JSON Schema 2020-12 — explicit and aligned with the event schema's proposed dialect; requires API Manager support and provider registration. (2) Follow an existing enterprise route/version convention and supported dialects — aligns with platform governance; requires that convention to be supplied.
- **Provisional assumption used:** Propose `POST /webhooks/quetzal` and `POST /webhooks/andina`, OpenAPI 3.1.0, and JSON Schema 2020-12. Mark only the fields needed for the proposed mapping as required; accept unknown fields so provider additions do not automatically break intake. These are contract proposals, not facts from the assessment.
- **Impact if incorrect:** API Manager import, provider registration, validation behavior, or schema tooling may need adjustment before deployment.
- **Who should answer:** API Manager owner and Payments Integration API owner.

