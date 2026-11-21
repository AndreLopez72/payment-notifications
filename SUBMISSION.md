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

- Practical part (Part B): Mule 4.9.9, Java 17, DataWeave, and MUnit 3.7.6 (provisional implementation toolchain). Java 17.0.21.1 and Maven 3.10.1 are installed; Maven could not resolve the Mule Maven Plugin because the default local repository was not writable and the retry failed JVM TLS certificate validation. Compilation and MUnit remain unverified.
- Infrastructure as code: Terraform CLI 1.9.8 in CI; AzureRM provider constraint `~> 5.2.0`.
- Pipeline: GitHub Actions. Pull request CI and manual-only staged `dev` → `test` → `prod` CD are defined; no workflow has run.
- CI run link (optional): [Not available]

## Where to start reading

1. [`docs/design/SOLUTION_DESIGN.md`](docs/design/SOLUTION_DESIGN.md) and its ADRs for the end-to-end proposal.
2. [`docs/EXECUTION_PLAN.md`](docs/EXECUTION_PLAN.md) for implementation increments, evidence, and remaining blockers.
3. [`docs/ASSUMPTIONS.md`](docs/ASSUMPTIONS.md) for provisional choices and unanswered platform/business questions.

## Known gaps and what I would do next

- Configure a writable Maven local repository and the required JVM-trusted certificate chain for the MuleSoft and Maven Central repositories, then rerun the Part B build/MUnit suite. Run `terraform fmt` and `terraform validate` when Terraform is available; the GitHub workflow files have not been run or independently syntax-validated.
- Confirm Azure region, SQL/Service Bus/Key Vault tiers, redundancy, workload identities, private networking, state backend, and budget with the platform owners. The monthly cost estimate remains open because these inputs are not in the assessment.
- Configure GitHub Environments, Azure OIDC federation, remote state, approvers, and least-privilege permissions before any deployment workflow use. No deployment has been performed.
- Confirm Mule-to-Azure identity, network, and telemetry support; Salesforce API Manager backend-token mediation; the exact on-call destination; and the v1 DLQ replay mechanism (A-02/A-14/A-22/A-26/A-29/A-30/A-31).
- Candidate ID, time spent, repository URL/visibility, and final submission SHA must be completed by the candidate. No real provider, Salesforce, or Azure service has been called.
