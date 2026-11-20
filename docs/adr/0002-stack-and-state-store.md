# ADR-0002: Mule 4 integration with relational state store

- **Status:** Proposed
- **Date:** 2026-11-19

## Context

The platform supports Mule 4 integration applications and API Manager. Mule 4 with DataWeave and MUnit is the assessment reference stack. Java 21 with Spring Boot 3 or Azure Functions is accepted if justified. The employer technology description also names MuleSoft, Java, Azure Functions, Container Apps, App Service, AKS, Service Bus, Azure SQL, and Cosmos DB. The exercise needs provider-isolated signature/mapping logic, durable acceptance, duplicate suppression, ordering state, an outbox, Salesforce retry state, and operational status lookup by provider identifiers. It requires choosing relational or non-relational persistence, but does not prescribe a store.

## Options considered

### Option 1 — Mule 4 on the enterprise integration platform + Azure SQL Database

- Pros: uses the reference stack and existing integration platform/API Manager; relational transactions and unique constraints fit inbox/outbox and provider-event uniqueness; query indexes support operations lookup; provider adapters can remain isolated from shared flow.
- Cons: Mule and Azure SQL connector/runtime compatibility and deployment/network setup must be validated; relational schema and migrations need ownership; a single relational store requires capacity and HA sizing.

### Option 2 — Java 21 with Spring Boot 3 or Azure Functions + non-relational store

- Pros: Java is explicitly accepted; Azure Functions is named as an accepted option; a non-relational store may scale key-based access patterns.
- Cons: requires a stack justification and does not use the provided Mule reference as directly; uniqueness, transactional outbox, ordering, and multi-key operations need store-specific design and validation. The assessment provides no evidence to select a particular non-relational store. It would add a second integration implementation stack without a documented need.

## Decision

Choose Mule 4 on the enterprise integration platform for all application flows: API-facing adapters, shared intake, outbox publisher, Salesforce consumer, and operations API. Route Salesforce REST calls through an internal Salesforce System API in API Manager; require the IdP machine-to-machine token at the gateway and use Salesforce OAuth client credentials for the Salesforce backend. Use Azure SQL Database as the relational state store and Azure Service Bus for canonical event delivery. This follows the assessment's reference implementation and makes use of the platform's stated ability to run Mule 4 applications. Azure Functions, Container Apps, App Service, and AKS remain valid company technologies, but are not added to this proposal because the existing integration platform can run the required flows. The proposal therefore has no Azure application compute to provision; IaC covers Azure managed data/messaging services and their identities/permissions.

Use provider-specific modules for raw-byte signature verification and payload mapping; share validation, persistence, event dispatch, and status behavior. Use SQL unique constraints for provider event idempotency and payment keys, and a transactionally written outbox to bridge the SQL commit to Service Bus publication. Use Azure Key Vault as the proposed secrets store, with least-privilege non-secret identity access. Keep payer PII and raw bodies out of persisted state.

This is a proposal based on the supplied reference stack, platform capabilities, and required lookup/uniqueness/state behavior; connector versions, SQL SKU, HA configuration, and exact Mule packaging remain to be validated in Part C. The scenario requires managed identities for Azure resources. The Mule platform's supported non-secret identity mechanism for Azure SQL and Service Bus access is not specified and must be verified; if it cannot meet the managed-identity requirement, revise the runtime placement before production rather than store Azure credentials.

## Consequences

- **Positive:** aligns with the described platform; provider-specific changes remain modular; relational constraints provide a clear basis for duplicate handling and operational searches; SQL transaction supports durable inbox/outbox state; API Manager governance avoids direct point-to-point Salesforce API calls.
- **Negative:** additional database operations and schema lifecycle; operational cost and capacity depend on selected SKU; Mule connector behavior and integration-platform network path need validation; API Manager adds a governed hop for Salesforce writes.
- **Risks and mitigations:** validate SQL throughput for 40 notifications/second and outage recovery; load-test connector and transaction behavior; verify managed identity/workload identity support from Mule to Azure and use least privilege; keep secrets in a secrets store; document schema migrations and backup/restore. If the Mule platform cannot reach Azure SQL/Service Bus under approved identity and network controls, revisit runtime placement.

