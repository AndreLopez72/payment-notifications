data "azurerm_client_config" "current" {}

locals {
  base_name = lower("${var.name_prefix}-${var.environment}-${var.resource_suffix}")
  common_tags = merge(var.tags, {
    environment = var.environment
    managed_by  = "terraform"
  })
}

resource "azurerm_resource_group" "payments" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_mssql_server" "payments" {
  name                          = "sql-${local.base_name}"
  resource_group_name           = azurerm_resource_group.payments.name
  location                      = azurerm_resource_group.payments.location
  version                       = "12.0"
  public_network_access_enabled = false
  tags                          = local.common_tags

  azuread_administrator {
    login_username              = var.sql_entra_admin_login
    object_id                   = var.sql_entra_admin_object_id
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_database" "payments" {
  name           = "sqldb-${local.base_name}"
  server_id      = azurerm_mssql_server.payments.id
  sku_name       = var.sql_database_sku_name
  max_size_gb    = var.sql_max_size_gb
  zone_redundant = var.sql_zone_redundant
  tags           = local.common_tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${local.base_name}"
  location            = azurerm_resource_group.payments.location
  resource_group_name = azurerm_resource_group.payments.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-sql-${local.base_name}"
    private_connection_resource_id = azurerm_mssql_server.payments.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-dns"
    private_dns_zone_ids = [var.private_dns_zone_ids.sql]
  }
}

resource "azurerm_servicebus_namespace" "payments" {
  name                          = "sb-${local.base_name}"
  location                      = azurerm_resource_group.payments.location
  resource_group_name           = azurerm_resource_group.payments.name
  sku                           = var.servicebus_sku
  public_network_access_enabled = false
  local_auth_enabled            = false
  minimum_tls_version           = "1.2"
  tags                          = local.common_tags
}

resource "azurerm_servicebus_topic" "canonical_events" {
  name         = "premium-payment-events"
  namespace_id = azurerm_servicebus_namespace.payments.id

  requires_duplicate_detection          = var.servicebus_duplicate_detection_enabled
  duplicate_detection_history_time_window = var.servicebus_duplicate_detection_enabled ? var.servicebus_duplicate_detection_window : null
}

resource "azurerm_servicebus_subscription" "salesforce" {
  name               = "salesforce"
  topic_id           = azurerm_servicebus_topic.canonical_events.id
  max_delivery_count = var.servicebus_max_delivery_count

  dead_lettering_on_message_expiration = true
}

resource "azurerm_private_endpoint" "servicebus" {
  name                = "pe-sb-${local.base_name}"
  location            = azurerm_resource_group.payments.location
  resource_group_name = azurerm_resource_group.payments.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-sb-${local.base_name}"
    private_connection_resource_id = azurerm_servicebus_namespace.payments.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "servicebus-dns"
    private_dns_zone_ids = [var.private_dns_zone_ids.servicebus]
  }
}

resource "azurerm_key_vault" "payments" {
  name                          = var.key_vault_name
  location                      = azurerm_resource_group.payments.location
  resource_group_name           = azurerm_resource_group.payments.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = lower(var.key_vault_sku)
  enable_rbac_authorization     = true
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  purge_protection_enabled      = true
  public_network_access_enabled = false
  tags                          = local.common_tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-kv-${local.base_name}"
  location            = azurerm_resource_group.payments.location
  resource_group_name = azurerm_resource_group.payments.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-kv-${local.base_name}"
    private_connection_resource_id = azurerm_key_vault.payments.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "key-vault-dns"
    private_dns_zone_ids = [var.private_dns_zone_ids.key_vault]
  }
}

resource "azurerm_role_assignment" "event_publisher" {
  scope                = azurerm_servicebus_topic.canonical_events.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = var.webhook_publisher_principal_object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "salesforce_receiver" {
  scope                = azurerm_servicebus_subscription.salesforce.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = var.salesforce_consumer_principal_object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "secrets_reader" {
  scope                = azurerm_key_vault.payments.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.secrets_reader_principal_object_id
  principal_type       = "ServicePrincipal"
}

data "azurerm_monitor_diagnostic_categories" "sql" {
  resource_id = azurerm_mssql_server.payments.id
}

resource "azurerm_monitor_diagnostic_setting" "sql" {
  name                       = "diag-sql-${local.base_name}"
  target_resource_id         = azurerm_mssql_server.payments.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.sql.log_category_types
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.sql.metrics
    content {
      category = metric.value
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "servicebus" {
  resource_id = azurerm_servicebus_namespace.payments.id
}

resource "azurerm_monitor_diagnostic_setting" "servicebus" {
  name                       = "diag-sb-${local.base_name}"
  target_resource_id         = azurerm_servicebus_namespace.payments.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.servicebus.log_category_types
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.servicebus.metrics
    content {
      category = metric.value
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "key_vault" {
  resource_id = azurerm_key_vault.payments.id
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-kv-${local.base_name}"
  target_resource_id         = azurerm_key_vault.payments.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.key_vault.log_category_types
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.key_vault.metrics
    content {
      category = metric.value
    }
  }
}
