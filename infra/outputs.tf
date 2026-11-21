output "resource_group_id" {
  description = "Resource group resource ID."
  value       = azurerm_resource_group.payments.id
}

output "sql_database_id" {
  description = "Azure SQL Database resource ID."
  value       = azurerm_mssql_database.payments.id
}

output "servicebus_topic_id" {
  description = "Canonical payment events topic resource ID."
  value       = azurerm_servicebus_topic.canonical_events.id
}

output "servicebus_subscription_id" {
  description = "Salesforce consumer subscription resource ID."
  value       = azurerm_servicebus_subscription.salesforce.id
}

output "key_vault_id" {
  description = "Key Vault resource ID; no secret values are output."
  value       = azurerm_key_vault.payments.id
}
