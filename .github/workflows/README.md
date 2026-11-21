# GitHub Actions

## CI (`ci.yml`)

CI runs for every pull request, pushes to `main`, and manual validation. It builds the Mule application and runs MUnit, checks Terraform formatting and configuration without an Azure backend, reviews dependency changes on pull requests, and runs CodeQL analysis for Java sources. The Mule build uses Java 17 because the selected assessment implementation is Mule 4; Java 21 applies to the alternative stack described by the root README.

| Gate | Why it is included |
|---|---|
| Mule `clean verify` / MUnit | Exercises the submitted integration behavior and fails CI when its build or automated behavior checks fail. |
| Terraform `fmt -check` and `validate` | Keeps infrastructure changes consistently formatted and rejects invalid Terraform configuration without contacting Azure or deploying. |
| Dependency review | Flags vulnerable dependency changes introduced by a pull request before merge. |
| CodeQL Java analysis | Scans the Java signature adapters for code-level security findings. |

Configure branch protection to require the CI checks before merging. The repository's GitHub security settings and environment protection rules must also permit the corresponding code-scanning and dependency-review features.

The Maven job requires dependency access for the MuleSoft artifacts in `practical/pom.xml`. If the repository or CI runner requires Anypoint credentials, configure them through the approved CI secret mechanism and Maven settings; do not commit credentials. A green result has not been observed from this workspace.

## CD (`deploy.yml`)

CD is manual-only and defines sequential `dev` → `test` → `prod` infrastructure deployment jobs. It is not triggered by this assessment. Configure GitHub Environments named `dev`, `test`, and `prod`, with required reviewers and deployment branch restrictions, especially for `prod`. Each environment must have:

- Variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` for an Azure workload identity with a GitHub Actions federated credential.
- Variables `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, and `TF_STATE_CONTAINER` for an existing, access-controlled Terraform state backend.
- Variable `TERRAFORM_INPUTS_JSON`, containing a JSON object with the required non-secret Terraform variables for that environment. Do not include secrets or credential values. See `infra/variables.tf`; the JSON includes the environment, approved resource identifiers, service settings, and principal object IDs.

Set up the federated credential subject for the matching repository and GitHub Environment. The deployment identity must have only the Azure permissions required to provision the approved resource group/resources and role assignments. Those Azure scopes and permissions must be approved by the platform owner. Protect remote state and environment configuration using the organization's access controls.

The workflow creates a plan and applies it only after the GitHub Environment's protection rules allow the job to start. It uses OIDC and the AzureRM backend's Entra authentication; it stores no Azure client secret. The AzureRM provider and backend receive the client, tenant, and subscription IDs as environment variables. `terraform apply` is present as CD code but has not been run. Do not dispatch this workflow for the assessment.

## Validation status

Workflow files are authored but have not been run or validated by GitHub Actions in this workspace. Terraform is not installed locally. External workflow validators and successful CI run links are not available; no CI or CD run is claimed.
