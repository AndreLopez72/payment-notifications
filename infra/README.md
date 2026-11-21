# Azure infrastructure

This directory contains Terraform for the Azure resources in the solution design. It provisions shared resources for the three countries in one Azure region; no country-specific Azure resource set is defined in the design.

## Toolchain

- Terraform CLI: `>= 1.9.0, < 2.0.0` (proposed compatibility range; validate against the execution environment).
- AzureRM provider: `~> 5.2.0`.
- Azure authentication: supplied by the operator's Azure CLI or an approved workload identity. Terraform variables contain resource identifiers and non-secret settings only. Do not put credentials, webhook keys, or Salesforce secrets in Terraform variables or state.
- Backend: the `azurerm` backend type is declared in `backend.tf`; backend resource values are intentionally not committed. Supply the approved remote state resource group, storage account, and container to `terraform init`. The deployment workflow uses an existing Azure Storage backend with Entra authentication. Configure and protect it before use; do not use local state for staged deployment.

## Structure and parameters

- `versions.tf` and `backend.tf`: Terraform/provider constraints and the Azure Storage backend type.
- `variables.tf`: required environment, location, existing network/DNS/Log Analytics IDs, approved SKU values, and Entra principal object IDs.
- `main.tf`: resource group, SQL server/database, Service Bus namespace/topic/subscription, Key Vault, private endpoints, least-privilege role assignments, and diagnostic settings.
- `outputs.tf`: non-secret resource IDs and names.

The assessment defines one Azure region for all three countries. `environment` is parameterized for `dev`, `test`, and `prod`; `location` is required because the exact region is not specified. Country is intentionally not a deployment parameter because the design shares the Azure resources across the three countries. The Terraform root is intended to be instantiated separately per environment with separately controlled state. No country-specific production data or credentials belong in tfvars.

Required existing platform inputs include a private-endpoint subnet, private DNS zones for SQL, Service Bus, and Key Vault, and the existing Log Analytics workspace. Identity object IDs and service SKUs must be supplied by the platform owner. Missing values deliberately have no defaults. Create environment-specific tfvars outside source control using only approved identifiers and non-secret values.

## Resources and scope

Terraform provisions Azure SQL, a Service Bus topic and subscription, Key Vault, private endpoints, role assignments, and diagnostic settings. The integration applications run on the enterprise Mule 4 platform according to the solution design, so this configuration creates no Azure compute. It references the existing Log Analytics workspace instead of creating a duplicate workspace.

Service Bus uses a topic subscription with dead-letter-on-expiration enabled and a configurable maximum delivery count. Application-level Salesforce failures remain represented by the SQL outbox/status design; the broker DLQ is for broker delivery failures. Replay procedures and full application DLQ mechanics remain subject to A-15.

## Validation (no deployment)

Validation status: **not run**. Terraform is not available in the current workspace. Once installed and AzureRM dependencies are available, run from this directory:

```powershell
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

These commands validate formatting and configuration only. Do not run `terraform apply` for this assessment. A successful local validation does not confirm Azure quota, network connectivity from Mule, role assignment authorization, SKU suitability, or cost. Resolve the applicable assumptions and supply approved values before any deployment outside the assessment.
