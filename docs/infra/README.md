# Infrastructure design

Part C's Terraform implementation and validation status are documented in [`../../infra/README.md`](../../infra/README.md). Azure service choices, alternatives, security notes, unresolved tiers, and the cost-estimate limitation are documented in [`AZURE_SERVICES.md`](AZURE_SERVICES.md).

Terraform references existing network, private DNS, identity, and Log Analytics resources. The environment-specific values are deliberately required inputs because the assessment does not provide them. No Azure resources have been deployed.
