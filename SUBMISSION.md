# Submission

> Candidate-specific submission details remain to be supplied. Do not send this repository until the remaining fields and checklist are complete.

## Candidate

| Field | Value |
|---|---|
| Candidate ID (provided by your recruiter) | [Not provided] |
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

- Practical part (Part B): Mule 4.9.9, Java 17, DataWeave, and MUnit 3.7.6 (provisional implementation toolchain). Java 17.0.21.1 and Maven 3.10.1 are installed locally; local dependency resolution was blocked by Maven cache permissions and JVM TLS certificate validation. GitHub Actions then reached dependency resolution but could not find the JSON and Java modules in the repositories configured at that time. The POM now includes all public repositories documented by MuleSoft. The candidate has no Enterprise Repository credentials; compilation and MUnit remain unverified.
- Infrastructure as code: Terraform CLI 1.9.8 in CI; AzureRM provider constraint `~> 5.2.0`.
- Pipeline: GitHub Actions. Pull request CI and manual-only staged `dev` → `test` → `prod` CD are defined. CI has run but has not passed; the deployment workflow has not run.
- CI run link (optional): [Not available]

## Where to start reading

1. [`docs/design/SOLUTION_DESIGN.md`](docs/design/SOLUTION_DESIGN.md) and its ADRs for the end-to-end proposal.
2. [`docs/EXECUTION_PLAN.md`](docs/EXECUTION_PLAN.md) for implementation increments, evidence, and remaining blockers.
3. [`docs/ASSUMPTIONS.md`](docs/ASSUMPTIONS.md) for provisional choices and unanswered platform/business questions.

## Known gaps and what I would do next

- Rerun CI with the documented public MuleSoft repositories to verify the Part B build/MUnit suite and CodeQL. If a required dependency remains unavailable without Enterprise access, report the build as unverified. For local Maven builds, use a writable cache and a JVM-trusted certificate chain. Terraform 1.9.8 `fmt` and backend-disabled `init` passed previously; local `validate` is blocked before schema validation by the AzureRM provider's local gRPC TLS handshake. GitHub Actions reached Terraform validation but failed on AzureRM 5.2.0 Key Vault RBAC and diagnostic metric schema names; fixes are committed and a successful rerun is pending. `actionlint` v1.7.10 passed for both workflow files.
- Review the provisional Mexico Central, SQL serverless/zone-redundant, and Service Bus Standard/IP-filtered profile in `docs/infra/AZURE_SERVICES.md`; obtain legal, platform, network, identity, load-test, and FinOps approval before treating its values or indicative cost range as production decisions.
- Configure GitHub Environments, Azure OIDC federation, remote state, approvers, and least-privilege permissions before any deployment workflow use. No deployment has been performed.
- Confirm Mule-to-Azure identity, network, and telemetry support; Salesforce API Manager backend-token mediation; the exact on-call destination; and the v1 DLQ replay mechanism (A-02/A-14/A-22/A-26/A-29/A-30/A-31).
- Candidate ID, time spent, repository URL/visibility, and final submission SHA must be completed by the candidate. No real provider, Salesforce, or Azure service has been called.
