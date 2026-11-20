# Practical part — Payment notification intake (MX, CO)

## Stack

- Mule runtime: 4.9.9
- Java runtime: 17
- HTTP Connector: 1.12.2
- Java Module: 2.0.8
- MUnit: 3.7.6
- Mule Maven Plugin: 4.10.4
- Maven: 3.10.0

These versions are a provisional, compatibility-based selection for this assessment; its documents do not prescribe exact versions. See A-24 in `docs/ASSUMPTIONS.md`. The MuleSoft documentation consulted includes the [Mule runtime Java support matrix](https://docs.mulesoft.com/release-notes/mule-runtime/java-adoption), [Mule Maven Plugin release notes](https://docs.mulesoft.com/release-notes/mule-maven-plugin/mule-maven-plugin-4.10.4-release-notes), [MUnit 3.7.6 compatibility](https://docs.mulesoft.com/release-notes/munit/munit-3.7.6-release-notes), [HTTP Connector 1.12.2 release notes](https://docs.mulesoft.com/release-notes/connector/connector-http), [Java Module reference](https://docs.mulesoft.com/java-module/latest/), [DataWeave hexadecimal conversion](https://docs.mulesoft.com/dataweave/latest/dw-binaries-functions-tohex), and [DataWeave timezone conversion](https://docs.mulesoft.com/dataweave/latest/dataweave-cookbook-change-time-zone).

## Build and tests

From this directory, with the selected JDK and Maven versions installed and the MuleSoft dependencies available:

```shell
mvn clean test
```

This command has **not been run in the current workspace** because Java and Maven executables are not available here. The MUnit suite is present, but its result remains unverified until it runs in an Anypoint or Maven environment.

## Project structure

- `src/main/java/com/meridian/payments/adapter/quetzal/QuetzalSignatureVerifier.java` — Quetzal raw-body HMAC verification and timestamp tolerance.
- `src/main/java/com/meridian/payments/adapter/andina/AndinaSignatureVerifier.java` — Andina raw-body HMAC verification and timestamp tolerance.
- `src/main/resources/dw/map-quetzal.dwl` — Quetzal provider payload to canonical payment-event mapping.
- `src/main/resources/dw/map-andina.dwl` — Andina provider payload to canonical payment-event mapping.
- `src/main/mule/provider-adapters.xml` — Mule subflow boundaries for both providers' signature verification and event mapping.
- `src/test/munit/provider-adapter-test-suite.xml` — signature-vector, rotation, retry identity, body mismatch, timestamp, privacy, and mapping tests for both providers.
- `src/test/resources/providers/quetzal/` — byte-for-byte copies of the fictional Quetzal test samples used by the signature tests.
- `src/test/resources/providers/andina/` — byte-for-byte copies of the fictional Andina test samples used by signature and mapping tests.

Each signature verifier is isolated from provider payload mapping and shared intake orchestration. The mappings emit the canonical fields defined in `docs/api/events/premium-payment.schema.json`, normalize event times to UTC, and do not copy payer or payment-method details from provider samples. HTTP intake, persistence, and publication are separate follow-on increments.

## Stubs and external services

This increment does not call Azure, a payment provider, Salesforce, a secrets store, or a message broker. The tests use the fictional sandbox secrets and signature vectors supplied in `reference/providers/quetzal-mx/WEBHOOK_SPEC.md` and `reference/providers/andina-co/WEBHOOK_SPEC.md`. Secret lookup, durable inbox/outbox, broker publication, and the HTTP listener are not implemented yet; later increments must keep them behind testable boundaries and stub them in tests.

## Known gaps

- The local workspace has no detected Java or Maven executable, so build and MUnit execution are not verified.
- The test secrets are assessment-provided fictional sandbox values and exist only in the MUnit test; they are not runtime configuration.
- The HTTP endpoint, durable acceptance, idempotency persistence, and canonical event publication remain to be implemented.
- No Azure deployment or real external call is made.
