# GitHub Actions

## CI (`ci.yml`)

CI runs for every pull request, pushes to `main`, and manual validation. It builds the Mule application and runs MUnit, validates OpenAPI and JSON Schema contracts, checks Terraform formatting and configuration without an Azure backend, scans changed commits for secrets, reviews dependency changes on pull requests, and runs CodeQL analysis for Java sources. The Mule build uses Java 17 because the selected assessment implementation is Mule 4; Java 21 applies to the alternative stack described by the root README.

| Gate | Why it is included |
|---|---|
| Mule `clean verify` / MUnit | Exercises the submitted integration behavior and fails CI when its build or automated behavior checks fail. |
| OpenAPI lint and JSON Schema metaschema validation | Rejects malformed or invalid API contracts before they reach providers or consumers. |
| Terraform `fmt -check` and `validate` | Keeps infrastructure changes consistently formatted and rejects invalid Terraform configuration without contacting Azure or deploying. |
| TruffleHog secret scan | Detects likely secret additions in changed commits without attempting to verify credentials against external services. It runs for pull requests and pushes, not manual whole-repository scans of the assessment's intentionally fictional reference material. |
| Dependency review | Flags vulnerable dependency changes introduced by a pull request before merge. |
| CodeQL Java analysis | Scans the Java signature adapters for code-level security findings. |

Configure branch protection to require the CI checks before merging. The repository's GitHub security settings and environment protection rules must also permit the corresponding code-scanning and dependency-review features.

The Mule build and CodeQL jobs resolve dependencies from the MuleSoft public repositories listed in `practical/pom.xml`. The candidate has a free MuleSoft learning account and no Enterprise Repository credentials. The complete CI workflow has not passed because MUnit cannot resolve its Enterprise runtime distribution; `TASKS.md` makes a successful CI link optional in this situation.

## CD (`deploy.yml`)

CD is manual-only and defines sequential `dev` → `test` → `prod` infrastructure deployment jobs. It is not triggered by this assessment. Configure GitHub Environments named `dev`, `test`, and `prod`, with required reviewers and deployment branch restrictions, especially for `prod`. Each environment must have:

- Variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` for an Azure workload identity with a GitHub Actions federated credential.
- Variables `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, and `TF_STATE_CONTAINER` for an existing, access-controlled Terraform state backend.
- Variable `TERRAFORM_INPUTS_JSON`, containing a JSON object with the required non-secret Terraform variables for that environment. Do not include secrets or credential values. See `infra/variables.tf`; the JSON includes the environment, approved resource identifiers, service settings, and principal object IDs.

Set up the federated credential subject for the matching repository and GitHub Environment. The deployment identity must have only the Azure permissions required to provision the approved resource group/resources and role assignments. Those Azure scopes and permissions must be approved by the platform owner. Protect remote state and environment configuration using the organization's access controls.

The workflow creates a plan and applies it only after the GitHub Environment's protection rules allow the job to start. It uses OIDC and the AzureRM backend's Entra authentication; it stores no Azure client secret. The AzureRM provider and backend receive the client, tenant, and subscription IDs as environment variables. Each deployment job is restricted in workflow code to `refs/heads/main`, and `jq` rejects a tfvars JSON whose `environment` differs from the current stage. Keep GitHub Environment reviewer and branch restrictions configured as an additional repository-side control. `terraform apply` is present as CD code but has not been run. Do not dispatch this workflow for the assessment.

## Validation status

`actionlint` v1.7.10 passed on both workflow files. In the [CI run for commit `33fe125`](https://github.com/AndreLopez72/payment-notifications/actions/runs/44944502626), Terraform format/validation, API contract validation, CodeQL Java analysis, and changed-commit secret scanning passed. Dependency review was skipped because this run was a push to `main`, not a pull request. Terraform CLI 1.9.8 local `fmt` and backend-disabled `init` passed previously; local `validate` remains blocked by the provider's gRPC TLS handshake before schema validation. The deployment workflow has not been run.

The practical project passed local Maven `clean process-classes` with Java 17 and Windows certificate-store trust. Local `clean verify` reached MUnit but could not start its embedded Mule 4.9.9 runtime because the distribution BOM was unavailable from accessible repositories; no test assertion ran. The CI run for `33fe125` likewise failed in the Mule build/MUnit job. A temporary Mule Kernel test resolved a public runtime but rejected the application because it requires `MULE_EE`; that test-only change was removed. MUnit assertions remain unverified.
