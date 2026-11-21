# Practical part — Payment notification intake (MX, CO)

## Stack

- Mule runtime: 4.9.9
- Java runtime: 17
- JSON Module: 2.5.11
- HTTP Connector: 1.12.2
- Java Module: 2.0.8
- MUnit: 3.7.6
- Mule Maven Plugin: 4.10.4
- Maven: 3.10.0

The canonical event is validated with JSON Module 2.5.11 against the Draft 2020-12 contract. Maven packages the schema from `docs/api/events/premium-payment.schema.json` as a classpath resource, keeping the API contract as the single source of truth. MuleSoft documents support for Draft 2020-12 and Mule 4.1.1 or later in the [JSON Module schema validation guide](https://docs.mulesoft.com/json-module/latest/json-schema-validation).

The assessment accepts Java 21 with Spring Boot 3 or Azure Functions as an alternative implementation stack. This practical project follows the selected Mule 4 reference stack in ADR-0002, so its Java module targets the Java version supported by the selected Mule runtime. These versions are a provisional, compatibility-based selection; see A-24 in `docs/ASSUMPTIONS.md`. The MuleSoft documentation consulted includes the [Mule runtime Java support matrix](https://docs.mulesoft.com/release-notes/mule-runtime/java-adoption), [Mule Maven Plugin release notes](https://docs.mulesoft.com/release-notes/mule-maven-plugin/mule-maven-plugin-4.10.4-release-notes), [MUnit 3.7.6 compatibility](https://docs.mulesoft.com/release-notes/munit/munit-3.7.6-release-notes), [HTTP Connector 1.12.2 release notes](https://docs.mulesoft.com/release-notes/connector/connector-http), [Java Module reference](https://docs.mulesoft.com/java-module/latest/), [DataWeave hexadecimal conversion](https://docs.mulesoft.com/dataweave/latest/dw-binaries-functions-tohex), and [DataWeave timezone conversion](https://docs.mulesoft.com/dataweave/latest/dataweave-cookbook-change-time-zone).

## Build and tests

From this directory, with the selected JDK and Maven versions installed and the MuleSoft dependencies available:

```shell
mvn clean test
```

The build was attempted with Java 17.0.21.1 (Zulu) and Maven 3.10.1. Maven's default local repository resolved to `C:\.m2\repository`, which was not writable in this workspace. Retrying with a writable temporary local repository reached dependency resolution, but the JVM rejected the TLS certificate chain from the MuleSoft and Maven Central repositories (`PKIX path building failed`). The Mule Maven Plugin could not be resolved, so compilation did not start and MUnit was not executed. Configure a writable Maven local repository and the required trusted certificate chain, then rerun the command; do not treat the test suite as passing evidence.

## Project structure

- `src/main/java/com/meridian/payments/adapter/quetzal/QuetzalSignatureVerifier.java` — Quetzal raw-body HMAC verification and timestamp tolerance.
- `src/main/java/com/meridian/payments/adapter/andina/AndinaSignatureVerifier.java` — Andina raw-body HMAC verification and timestamp tolerance.
- `src/main/resources/dw/map-quetzal.dwl` — Quetzal provider payload to canonical payment-event mapping.
- `src/main/resources/dw/map-andina.dwl` — Andina provider payload to canonical payment-event mapping.
- `src/main/mule/provider-adapters.xml` — provider signature verification, canonical JSON Schema validation, provider/country/currency checks, and mapping boundaries.
- `src/main/mule/webhook-intake.xml` — local HTTP endpoints and shared signature, mapping, validation, and acknowledgement orchestration.
- `src/main/mule/integration-ports.xml` — fail-closed placeholders for secret retrieval and durable persistence.
- `src/main/mule/outbox-dispatch.xml` — canonical outbox dispatch boundary with stable event message IDs and acknowledgement handling.
- `src/test/munit/provider-adapter-test-suite.xml` — signature-vector, rotation, retry identity, body mismatch, timestamp, privacy, and mapping tests for both providers.
- `src/test/munit/webhook-intake-test-suite.xml` — shared-flow tests for valid acceptance, canonical schema enum/additional-property rejection, repeated-event deduplication, missing secrets and invalid signatures, sensitive-context cleanup, persistence failure, and Andina business-data holds.
- `src/test/munit/outbox-dispatch-test-suite.xml` — broker acknowledgement, publish-failure, and outbox-status update cases.
- `src/test/resources/providers/quetzal/` — byte-for-byte copies of the fictional Quetzal test samples used by the signature tests.
- `src/test/resources/providers/andina/` — byte-for-byte copies of the fictional Andina test samples used by signature and mapping tests.

Each signature verifier is isolated from provider payload mapping and shared intake orchestration. The mappings emit the canonical fields defined in `docs/api/events/premium-payment.schema.json`, normalize event times to UTC, and do not copy payer or payment-method details from provider samples. Before either persistence port is called, the flow removes the raw body, signature, and secret variables from the event context. Both provider flows also clear those sensitive variables after every outcome, including signature and secret-availability rejection. The HTTP flows call fail-closed secret and persistence ports; MUnit supplies controlled test doubles. They do not implement a durable store or broker publisher.

## Stubs and external services

This increment does not call Azure, a payment provider, Salesforce, a secrets store, or a message broker. The tests use the fictional sandbox secrets and signature vectors supplied in `reference/providers/quetzal-mx/WEBHOOK_SPEC.md` and `reference/providers/andina-co/WEBHOOK_SPEC.md`. Runtime secret lookup, durable inbox/outbox persistence and polling, and broker publication remain to be implemented behind the existing testable ports.

When a runtime secret provider and durable store are configured, the local listeners expose `POST /webhooks/quetzal` and `POST /webhooks/andina` on port `8081`. As checked into this assessment, the secret and persistence ports fail closed. The MUnit duplicate test uses a test-scoped event-ID collection to exercise the idempotency boundary; it does not model SQL durability, transaction isolation, or restart recovery.

## Known gaps

- Java 17.0.21.1 and Maven 3.10.1 are installed. Build and MUnit execution remain unverified because Maven could not resolve the Mule Maven Plugin: the default local repository was not writable, and the retry was blocked by JVM TLS certificate validation for the configured artifact repositories.
- The test secrets are assessment-provided fictional sandbox values and exist only in the MUnit test; they are not runtime configuration.
- The secret and persistence ports currently fail closed; no durable acceptance or idempotency store is implemented.
- Canonical schema validation cases are authored but remain unexecuted until Maven can validate the configured artifact repository certificate chain.
- The outbox dispatcher has no SQL poller or real broker connector; broker acknowledgement and status transitions are exercised only through MUnit stubs.
- No Azure deployment or real external call is made.
