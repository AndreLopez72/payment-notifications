# Azure infrastructure

This directory contains Terraform for the Azure resources in the solution design. It provisions shared resources for the three countries in one Azure region; no country-specific Azure resource set is defined in the design.

## Toolchain

- Terraform CLI: `>= 1.9.0, < 2.0.0` (proposed compatibility range; validate against the execution environment).
- AzureRM provider: `~> 5.2.0`.
- Azure authentication: supplied by the operator's Azure CLI or an approved workload identity. Terraform variables contain resource identifiers and non-secret settings only. Do not put credentials, webhook keys, or Salesforce secrets in Terraform variables or state.
- Backend: the `azurerm` backend type is declared in `backend.tf`; backend resource values are intentionally not committed. Supply the approved remote state resource group, storage account, and container to `terraform init`. The deployment workflow uses an existing Azure Storage backend with Entra authentication. Configure and protect it before use; do not use local state for staged deployment.

## Structure and parameters

- `versions.tf` and `backend.tf`: Terraform/provider constraints and the Azure Storage backend type.
- `.terraform.lock.hcl`: exact AzureRM provider selection and package checksums produced by initialization.
- `variables.tf`: required environment, location, existing network/DNS/Log Analytics IDs, approved SKU and capacity values, Service Bus IP rules, and Entra principal object IDs.
- `main.tf`: resource group, SQL server/database, Service Bus namespace/topic/subscription, Key Vault, conditional Service Bus network mode, private endpoints, least-privilege role assignments, and diagnostic settings.
- `outputs.tf`: non-secret resource IDs and names.

The assessment defines one Azure region for all three countries. `docs/infra/AZURE_SERVICES.md` recommends Mexico Central provisionally based on the documented traffic mix and zonal service availability; legal, platform, latency, and full-cost approval remain open. `location` remains an explicit input, not a deployment default. `environment` is parameterized for `dev`, `test`, and `prod`. Country is intentionally not a deployment parameter because the design shares the Azure resources across the three countries. The Terraform root is intended to be instantiated separately per environment with separately controlled state. No country-specific production data or credentials belong in tfvars.

Required existing platform inputs include a private-endpoint subnet, private DNS zones for SQL and Key Vault (plus Service Bus when Premium is selected), and the existing Log Analytics workspace. Standard Service Bus requires approved stable Mule egress IP/CIDR rules; it uses a deny-by-default public firewall and no Service Bus private endpoint. Premium disables public access and creates a Service Bus private endpoint. The proposed SQL starting profile is serverless General Purpose Gen5, 0.5–2 vCore, zone redundant, with auto-pause disabled. Identity object IDs, capacity, SKU values, and platform resource IDs remain inputs without defaults and require approval before use. Create environment-specific tfvars outside source control using only approved identifiers and non-secret values.

## Resources and scope

Terraform provisions Azure SQL, a Service Bus topic and subscription, Key Vault, the selected Service Bus network path, private endpoints, role assignments, and diagnostic settings. SQL and Key Vault use private endpoints. The Service Bus endpoint mode is conditional: Standard plus approved IP filtering, or Premium plus a private endpoint. These modes must not be combined. The integration applications run on the enterprise Mule 4 platform according to the solution design, so this configuration creates no Azure compute. It references the existing Log Analytics workspace instead of creating a duplicate workspace.

Service Bus uses a topic subscription with dead-letter-on-expiration enabled and a configurable maximum delivery count. Application-level Salesforce failures remain represented by the SQL outbox/status design; the broker DLQ is for broker delivery failures. Replay procedures and full application DLQ mechanics remain subject to A-15.

## Validation (no deployment)

Validation status (Terraform CLI 1.9.8, with the backend disabled):

- `terraform fmt -recursive`: passed; `terraform fmt -check -recursive` now passes.
- `terraform init -backend=false -input=false`: passed. AzureRM provider 5.2.0 was downloaded and its signed package was accepted; `.terraform.lock.hcl` records the provider selection and checksums.
- `terraform validate -no-color`: blocked before configuration validation because the provider process failed its local gRPC TLS handshake (`x509: certificate signed by unknown authority`). The provider did not return its schema, so this is not a successful validation result.
- A GitHub Actions Terraform validation run reached the AzureRM 5.2.0 schema and reported the obsolete Key Vault RBAC argument and diagnostic metric block names. The configuration now uses `rbac_authorization_enabled` and `enabled_metric`; a successful rerun is still required.

Commands used from this directory:

```powershell
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

These commands validate formatting and configuration only. `terraform init -backend=false` does not configure or access the Azure Storage backend. No Azure resources were created or changed. Do not run `terraform apply` for this assessment. A successful local validation would not confirm Azure quota, network connectivity from Mule, role assignment authorization, SKU suitability, or cost. Resolve the applicable assumptions and supply approved values before any deployment outside the assessment.
