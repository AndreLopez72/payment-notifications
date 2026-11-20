# API contracts

## Webhook intake

`webhooks.openapi.yaml` describes the proposed API Manager endpoints for Quetzal Pagos and Andina Pay. Verify provider signatures over the exact raw request-body bytes before parsing the JSON. The request schemas accept unknown properties so provider additions do not automatically break intake; the Andina specification explicitly requires unknown fields to be ignored.

The proposed paths are `/webhooks/quetzal` and `/webhooks/andina`. The assessment does not provide route paths or the API Manager base URL. Confirm the paths with the API Manager owner and register the corresponding URLs with the providers before deployment. The paths and OpenAPI dialect are provisional and tracked in `docs/ASSUMPTIONS.md` (A-23).

The contract proposes `204` after durable acceptance, including recognized duplicates; `400` for invalid signature, timestamp, or payload; and `500` when durable acceptance fails. The provider references do not specify exact error codes for invalid requests; this response mapping is provisional under A-12 in `docs/ASSUMPTIONS.md`.

## Canonical event evolution

`events/premium-payment.schema.json` defines the proposed canonical event with `schemaVersion: "1.0"`.

- Add optional fields without changing the meaning of existing fields within a major event version.
- Treat removing or renaming a field, changing its meaning or type, changing a required field, or narrowing an accepted value as a breaking change that requires a new major version and consumer coordination.
- Keep provider-specific fields out of the canonical contract unless they have a provider-independent business meaning.
- Never add payer personal data, payment tokens, secrets, or raw webhook bodies to the canonical event.
- Validate producer output against the schema and coordinate proposed changes with Finance and Notifications before publishing them.

The field set, requiredness, versioning rule, OpenAPI dialect, and JSON Schema dialect are proposals where the assessment does not prescribe a value. Track them in `docs/ASSUMPTIONS.md` (A-19 and A-23).
