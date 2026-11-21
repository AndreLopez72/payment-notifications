# API contracts

## Webhook intake

`webhooks.openapi.yaml` describes the proposed API Manager endpoints for Quetzal Pagos and Andina Pay. Verify provider signatures over the exact raw request-body bytes before parsing the JSON. The request schemas accept unknown properties so provider additions do not automatically break intake; the Andina specification explicitly requires unknown fields to be ignored.

The proposed paths are `/webhooks/quetzal` and `/webhooks/andina`. The assessment does not provide route paths or the API Manager base URL. Confirm the paths with the API Manager owner and register the corresponding URLs with the providers before deployment. The paths and OpenAPI dialect are provisional and tracked in `docs/ASSUMPTIONS.md` (A-23).

Each operation declares its provider-specific HMAC signature header as an OpenAPI security scheme. The `apiKey` scheme describes how the signature is carried in the header; the provider specification and operation description define the HMAC calculation and raw-byte verification. The repository-level `redocly.yaml` keeps the recommended lint rules except `no-empty-servers` and `info-license`: the assessment specifies neither an API Manager base URL nor a license for this contract. Set those values and restore the rules when the API Manager owner and repository owner supply them.

The contract proposes `204` after durable acceptance, including recognized duplicates and authenticated business-data errors recorded for operational correction without publishing a canonical event; `400` for invalid signature, timestamp, or structurally invalid payload; and `503` when a secret or durable acceptance is unavailable. Unexpected listener errors default to `500`. The provider references do not specify exact error codes for invalid requests; this response mapping is provisional under A-12 in `docs/ASSUMPTIONS.md`.

## Canonical event evolution

`events/premium-payment.schema.json` defines the proposed canonical event with `schemaVersion: "1.0"`.

- Add optional fields without changing the meaning of existing fields within a major event version.
- Treat removing or renaming a field, changing its meaning or type, changing a required field, or narrowing an accepted value as a breaking change that requires a new major version and consumer coordination.
- Keep provider-specific fields out of the canonical contract unless they have a provider-independent business meaning.
- Reject unregistered properties in the canonical event so provider-specific or personal fields cannot pass through unnoticed.
- Never add payer personal data, payment tokens, secrets, or raw webhook bodies to the canonical event.
- Validate producer output against the schema and coordinate proposed changes with Finance and Notifications before publishing them.
- Part B's Mule intake validates each mapped canonical event against this Draft 2020-12 schema before it can reach the persistence port. The implementation loads this file as a classpath resource from the Maven build, so the documented contract remains the validation source.

The field set, requiredness, versioning rule, OpenAPI dialect, and JSON Schema dialect are proposals where the assessment does not prescribe a value. Track them in `docs/ASSUMPTIONS.md` (A-19 and A-23).
