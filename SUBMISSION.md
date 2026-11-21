# Submission

> Candidate-specific submission details remain to be supplied. Do not send this repository until the remaining fields and checklist are complete.

## Candidate

| Field | Value |
|---|---|
| Candidate ID (provided by your recruiter) | [Not provided] |
| Repository URL (from Git remote) | https://github.com/AndreLopez72/payment-notifications |
| Repository visibility | Public (verified on 2026-11-21) |
| Final commit SHA | [Record the repository HEAD selected for submission] |
| Date and time of submission (with time zone) | [Not submitted] |

## Time spent

| Part | Approximate time |
|---|---|
| A. Integration and data design | [Not tracked] |
| B. Integration component | [Not tracked] |
| C. Azure IaC and CI/CD | [Not tracked] |
| D. Operations | [Not tracked] |
| E. Code review | [Not tracked] |
| F. Responsible AI | [Not tracked] |
| **Total** | [Not tracked] |

## Stack

- Practical part (Part B): Mule 4.9.9, Java 17, DataWeave, and MUnit 3.7.6 (provisional implementation toolchain). Java 17.0.21.1 and Maven 3.10.1 built the application through `clean process-classes` locally using a writable cache and Windows certificate-store trust. `clean verify` reached MUnit, but the embedded Mule 4.9.9 runtime distribution BOM was unavailable from the repositories accessible to the candidate. A temporary Mule Kernel run rejected the application because it requires `MULE_EE`; the test-only change was removed. No MUnit assertion ran. The candidate has no Enterprise Repository credentials.
- Infrastructure as code: Terraform CLI 1.9.8 in CI; AzureRM provider constraint `~> 5.2.0`.
- Pipeline: GitHub Actions. Pull request CI and manual-only staged `dev` → `test` → `prod` CD are defined. The latest CI passed Terraform, contracts, CodeQL, and changed-commit secret scanning, but the workflow failed at MUnit runtime resolution. The deployment workflow has not run.
- CI run link (optional): [Run for `33fe125`](https://github.com/AndreLopez72/payment-notifications/actions/runs/44944502626) — failed at Mule/MUnit; no successful CI run is claimed.

## Where to start reading

1. [`docs/design/SOLUTION_DESIGN.md`](docs/design/SOLUTION_DESIGN.md) and its ADRs for the end-to-end proposal.
2. [`docs/EXECUTION_PLAN.md`](docs/EXECUTION_PLAN.md) for implementation increments, evidence, and remaining blockers.
3. [`docs/ASSUMPTIONS.md`](docs/ASSUMPTIONS.md) for provisional choices and unanswered platform/business questions.

## Known gaps and what I would do next

- On 2026-11-21, local Maven `clean process-classes` passed with `JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStoreType=Windows-ROOT`; TLS verification was not disabled. `clean verify` failed when MUnit could not resolve the embedded-runtime distribution BOM. Both Java signature adapters also compiled directly with `javac --release 17`, and a temporary harness passed one supplied valid vector and one expiry case for each provider. Integrated MUnit cases are authored and parse as XML, but have not run. Mule's static analyzer warned on the packaged JSON Schema resource, so runtime schema validation still needs a runnable MUnit environment.
- The CI run for `33fe125` passed Terraform format/validation, API contract validation, CodeQL, and changed-commit secret scanning. MUnit failed before assertions because the Enterprise runtime BOM was unavailable. `TASKS.md` permits delivery without a successful CI link when MuleSoft Enterprise dependencies require credentials the candidate does not have. Terraform 1.9.8 local `fmt` and backend-disabled `init` passed previously; local `validate` was blocked by the AzureRM provider's gRPC TLS handshake. `actionlint` v1.7.10 passed for both workflow files.
- Review the provisional Mexico Central, SQL serverless/zone-redundant, and Service Bus Standard/IP-filtered profile in `docs/infra/AZURE_SERVICES.md`; obtain legal, platform, network, identity, load-test, and FinOps approval before treating its values or indicative cost range as production decisions.
- Configure GitHub Environments, Azure OIDC federation, remote state, approvers, and least-privilege permissions before any deployment workflow use. No deployment has been performed.
- Confirm Mule-to-Azure identity, network, and telemetry support; Salesforce API Manager backend-token mediation; the exact on-call destination; and the v1 DLQ replay mechanism (A-02/A-14/A-22/A-26/A-29/A-30/A-31).
- Candidate ID, time spent, submission date/time, and final submission SHA must be completed by the candidate. The repository URL and public visibility were checked against GitHub. No real provider, Salesforce, or Azure service has been called.
