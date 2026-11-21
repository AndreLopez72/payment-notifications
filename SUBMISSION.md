# Submission

> Candidate-specific submission details remain to be supplied. Do not send this repository until the remaining fields and checklist are complete.

## Candidate

| Field | Value |
|---|---|
| Candidate ID (provided by your recruiter) | [Not provided] |
| Repository URL (from Git remote) | https://github.com/AndreLopez72/payment-notifications |
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

- Practical part (Part B): Mule 4.9.9, Java 17, DataWeave, and MUnit 3.7.6 (provisional implementation toolchain). Java 17.0.21.1 and Maven 3.10.1 built the application through `clean process-classes` locally using a writable cache and Windows certificate-store trust. `clean verify` reached MUnit, but the embedded Mule 4.9.9 runtime distribution BOM was unavailable from the repositories accessible to the candidate. No MUnit assertion ran. The candidate has no Enterprise Repository credentials; a successful CI run is pending.
- Infrastructure as code: Terraform CLI 1.9.8 in CI; AzureRM provider constraint `~> 5.2.0`.
- Pipeline: GitHub Actions. Pull request CI and manual-only staged `dev` → `test` → `prod` CD are defined. CI has run but has not passed; the deployment workflow has not run.
- CI run link (optional): [Not available]

## Where to start reading

1. [`docs/design/SOLUTION_DESIGN.md`](docs/design/SOLUTION_DESIGN.md) and its ADRs for the end-to-end proposal.
2. [`docs/EXECUTION_PLAN.md`](docs/EXECUTION_PLAN.md) for implementation increments, evidence, and remaining blockers.
3. [`docs/ASSUMPTIONS.md`](docs/ASSUMPTIONS.md) for provisional choices and unanswered platform/business questions.

## Known gaps and what I would do next

- On 2026-11-21, local Maven `clean process-classes` passed with `JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStoreType=Windows-ROOT`; TLS verification was not disabled. `clean verify` failed when MUnit could not resolve the embedded-runtime distribution BOM. Both Java signature adapters also compiled directly with `javac --release 17`, and a temporary harness passed one supplied valid vector and one expiry case for each provider. Integrated MUnit cases are authored and parse as XML, but have not run. Mule's static analyzer warned on the packaged JSON Schema resource, so runtime schema validation also needs a runnable MUnit environment. The audit follow-up commits are local; CI has not run against them because they have not been pushed.
- Rerun CI with the documented public MuleSoft repositories to verify Part B/MUnit and CodeQL. If the MUnit runtime artifact remains unavailable without Enterprise access, report tests as unverified, as `TASKS.md` allows. Terraform 1.9.8 `fmt` and backend-disabled `init` passed previously; local `validate` was blocked before schema validation by the AzureRM provider's local gRPC TLS handshake. GitHub Actions reached Terraform validation but failed on AzureRM 5.2.0 Key Vault RBAC and diagnostic metric schema names; fixes are committed and a successful rerun is pending. `actionlint` v1.7.10 passed for both workflow files.
- Review the provisional Mexico Central, SQL serverless/zone-redundant, and Service Bus Standard/IP-filtered profile in `docs/infra/AZURE_SERVICES.md`; obtain legal, platform, network, identity, load-test, and FinOps approval before treating its values or indicative cost range as production decisions.
- Configure GitHub Environments, Azure OIDC federation, remote state, approvers, and least-privilege permissions before any deployment workflow use. No deployment has been performed.
- Confirm Mule-to-Azure identity, network, and telemetry support; Salesforce API Manager backend-token mediation; the exact on-call destination; and the v1 DLQ replay mechanism (A-02/A-14/A-22/A-26/A-29/A-30/A-31).
- Candidate ID, time spent, repository visibility, and final submission SHA must be completed or verified by the candidate. The repository URL comes from the configured Git remote. No real provider, Salesforce, or Azure service has been called.
