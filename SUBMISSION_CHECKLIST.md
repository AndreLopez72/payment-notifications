# Submission checklist

Tick every item before you send your repository URL. Missing items are scored as missing.

## General
- [ ] `SUBMISSION.md` completed (including the final commit SHA you will send to your recruiter)
- [x] `AI_USAGE.md` completed
- [x] `docs/ASSUMPTIONS.md` records the provisional assumptions made during the work
- [ ] No secrets, tokens or real personal data anywhere in the repository or its history
- [ ] Repository is **public**

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
- [x] Automated tests in `practical/` (authored; not executed locally)
- [x] `practical/README.md`

## Part C — Azure IaC and CI/CD
- [x] Bicep or Terraform in `infra/`, with `infra/README.md` (a GitHub Actions validate run found AzureRM 5.2.0 schema errors; the field names were corrected and a successful rerun remains pending; local validate is blocked by the provider process TLS handshake)
- [x] `docs/infra/AZURE_SERVICES.md` (illustrative order-of-magnitude monthly estimate and exclusions documented; target values remain open under A-17/A-32)
- [x] Pipeline definition in `.github/workflows/` or `pipelines/` (`actionlint` v1.7.10 passed; one GitHub Actions CI run failed at Terraform schema validation; rerun pending)

## Part D — Operations
- [x] `docs/operations/OPERATIONS.md`
- [x] `docs/operations/INC-0412-RESPONSE.md`

## Part E — Code review
- [x] `pr-review/REVIEW.md`

## Part F — Responsible AI
- [x] `AI_USAGE.md`
- [x] `docs/ai/AI_GUIDELINES.md`

## Validation and remaining submission details

- Terraform formatting and backend-disabled initialization passed previously. Local `terraform validate` stopped before configuration validation because the AzureRM provider failed its local gRPC TLS handshake. GitHub Actions reached Terraform schema validation and failed on Key Vault RBAC and diagnostic metric field names; the code now uses the AzureRM 5.2.0 names, and a successful rerun is pending. `actionlint` v1.7.10 passed on both workflow files. Local Maven dependency resolution was blocked by cache permissions and JVM TLS certificate validation. GitHub Actions later reached dependency resolution but could not find the JSON and Java modules in the public repositories. The POM now includes the MuleSoft Enterprise Repository, and CI expects authorized credentials in repository secrets. Compilation and MUnit remain unverified; do not treat authored workflows or tests as passing evidence.
- The assessment's provider test vectors and PR-214 contents are fictional reference material. Review the full repository and its Git history for secrets before publishing; repository visibility has not been verified.
- Candidate ID, actual time spent, repository URL/visibility, and final submission commit SHA remain for the candidate to complete in `SUBMISSION.md`.
