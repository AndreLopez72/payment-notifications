# Submission checklist

Tick every item before you send your repository URL. Missing items are scored as missing.

## General
- [ ] `SUBMISSION.md` completed (including the final commit SHA you will send to your recruiter)
- [x] `AI_USAGE.md` completed
- [x] `docs/ASSUMPTIONS.md` records the provisional assumptions made during the work
- [ ] No secrets, tokens or real personal data anywhere in the repository or its history
- [x] Repository is **public** (verified through GitHub's public repository API on 2026-11-21)

## Part A — Integration and data design
- [x] `docs/design/SOLUTION_DESIGN.md` (context diagram, sequence diagram, canonical event and mapping, idempotency and ordering, error handling, capacity, data, FR7)
- [x] `docs/adr/0001-*.md` — Integration with Salesforce
- [x] `docs/adr/0002-*.md` — Implementation stack and data store
- [x] `docs/adr/0003-*.md` — optional

## Part B — Integration component
- [x] `docs/api/webhooks.openapi.yaml`
- [x] `docs/api/events/premium-payment.schema.json`
- [x] `docs/api/README.md`
- [x] Implementation in `practical/` for Quetzal Pagos (MX) and Andina Pay (CO)
- [x] Automated tests in `practical/` (authored; MUnit reached runtime startup but no assertions executed)
- [x] `practical/README.md`

## Part C — Azure IaC and CI/CD
- [x] Bicep or Terraform in `infra/`, with `infra/README.md` (Terraform format and validation passed in GitHub Actions for `33fe125`; local validation remains blocked by the provider process TLS handshake)
- [x] `docs/infra/AZURE_SERVICES.md` (illustrative order-of-magnitude monthly estimate and exclusions documented; target values remain open under A-17/A-32)
- [x] Pipeline definition in `.github/workflows/` or `pipelines/` (`actionlint` v1.7.10 passed; the CI run for `33fe125` passed Terraform, contracts, CodeQL, and changed-commit secret scanning; MUnit failed at Enterprise runtime resolution)

## Part D — Operations
- [x] `docs/operations/OPERATIONS.md`
- [x] `docs/operations/INC-0412-RESPONSE.md`

## Part E — Code review
- [x] `pr-review/REVIEW.md`

## Part F — Responsible AI
- [x] `AI_USAGE.md`
- [x] `docs/ai/AI_GUIDELINES.md`

## Validation and remaining submission details

- Local Maven `clean process-classes` passed on 2026-11-21 with Java 17.0.21.1, Maven 3.10.1, a writable temporary repository, and Windows certificate-store trust. `clean verify` reached MUnit, but the embedded Mule 4.9.9 runtime distribution BOM was unavailable from accessible repositories; no test assertion ran. A temporary Mule Kernel run rejected the application because it requires `MULE_EE`; the test-only change was removed. The integrated suite parses as XML but remains unexecuted.
- Static checks parsed eight Mule/MUnit XML files and the canonical JSON Schema; all local links in 35 Markdown files resolved. Both Java signature adapters compiled directly, and a temporary harness passed valid/expired vector cases for each provider. A high-confidence credential-pattern scan across 31 reachable commits found no matches. The seven copied provider sample payloads match the assessment references byte-for-byte; the additional test-only email uses `example.invalid`. `.gitignore` excludes common local credential files, Maven settings, and Terraform plans/variable files. These checks and the passing changed-commit CI secret scan do not prove the absence of every possible historical secret; the general secrets/history checkbox remains open for candidate confirmation.
- In the [CI run for `33fe125`](https://github.com/AndreLopez72/payment-notifications/actions/runs/44944502626), Terraform format/validation, API contract validation, CodeQL, and changed-commit secret scanning passed. Dependency review was skipped on the push event. The Mule build/MUnit job failed before assertions because the Enterprise runtime artifact could not be resolved without credentials. Local Terraform validation stopped before configuration validation because of the AzureRM provider's gRPC TLS handshake. No Azure deployment was run.
- The assessment's provider test vectors and PR-214 contents are fictional reference material; PR-214 intentionally includes a live-looking but fictional credential as a review finding. It must not be reused. The public repository and its latest pushed SHA were confirmed through GitHub's public API. Candidate confirmation of the repository-wide secrets/history review remains open.
- Candidate ID, actual time spent, submission time, and final submission commit SHA remain for the candidate to complete in `SUBMISSION.md`.
