variable "environment" {
  description = "Deployment environment. Use a separate Terraform state for each environment."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "location" {
  description = "Approved Azure region shared by the three countries."
  type        = string
}

variable "name_prefix" {
  description = "Organization/project prefix used in Azure resource names."
  type        = string
}

variable "resource_suffix" {
  description = "Approved unique suffix for globally unique Azure resource names."
  type        = string
}

variable "key_vault_name" {
  description = "Approved globally unique Key Vault name (3-24 letters, numbers, or hyphens)."
  type        = string

  validation {
    condition     = length(var.key_vault_name) >= 3 && length(var.key_vault_name) <= 24 && can(regex("^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])$", var.key_vault_name))
    error_message = "key_vault_name must be 3-24 characters, start and end with a letter or number, and contain only letters, numbers, or hyphens."
  }
}

variable "tags" {
  description = "Organization-approved resource tags."
  type        = map(string)
  default     = {}
}

variable "private_endpoint_subnet_id" {
  description = "ID of an existing subnet approved for private endpoints."
  type        = string
}

variable "private_dns_zone_ids" {
  description = "IDs of existing private DNS zones for SQL, Service Bus, and Key Vault."
  type = object({
    sql        = string
    servicebus = string
    key_vault  = string
  })
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the existing platform Log Analytics workspace."
  type        = string
}

variable "sql_database_sku_name" {
  description = "Approved Azure SQL Database SKU name; to be selected after capacity and cost validation."
  type        = string
}

variable "sql_max_size_gb" {
  description = "Approved maximum database size in GB."
  type        = number
}

variable "sql_zone_redundant" {
  description = "Whether the approved SQL tier should use zone redundancy."
  type        = bool
}

variable "sql_entra_admin_object_id" {
  description = "Object ID of the approved Entra administrator for the SQL server."
  type        = string
}

variable "sql_entra_admin_login" {
  description = "Display/login name of the approved Entra administrator for the SQL server."
  type        = string
}

variable "servicebus_sku" {
  description = "Approved Service Bus namespace SKU. Basic does not support topics."
  type        = string

  validation {
    condition     = contains(["Standard", "Premium"], var.servicebus_sku)
    error_message = "servicebus_sku must be Standard or Premium because the design uses a topic."
  }
}

variable "servicebus_max_delivery_count" {
  description = "Approved delivery-attempt limit before Service Bus dead-letters a message."
  type        = number

  validation {
    condition     = var.servicebus_max_delivery_count >= 1 && floor(var.servicebus_max_delivery_count) == var.servicebus_max_delivery_count
    error_message = "servicebus_max_delivery_count must be a positive whole number."
  }
}

variable "servicebus_duplicate_detection_enabled" {
  description = "Approved decision from A-25 on broker-side duplicate detection."
  type        = bool
}

variable "servicebus_duplicate_detection_window" {
  description = "Approved Service Bus duplicate-detection window, supplied as an ISO 8601 duration."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !var.servicebus_duplicate_detection_enabled || (var.servicebus_duplicate_detection_window != null && length(trimspace(var.servicebus_duplicate_detection_window)) > 0)
    error_message = "Provide an approved duplicate-detection window when broker duplicate detection is enabled."
  }
}

variable "key_vault_sku" {
  description = "Approved Key Vault SKU."
  type        = string

  validation {
    condition     = contains(["standard", "premium"], lower(var.key_vault_sku))
    error_message = "key_vault_sku must be standard or premium."
  }
}

variable "webhook_publisher_principal_object_id" {
  description = "Object ID of the approved workload identity that publishes canonical events."
  type        = string
}

variable "salesforce_consumer_principal_object_id" {
  description = "Object ID of the approved workload identity that receives canonical events."
  type        = string
}

variable "secrets_reader_principal_object_id" {
  description = "Object ID of the approved workload identity that reads required Key Vault secrets."
  type        = string
}

variable "key_vault_soft_delete_retention_days" {
  description = "Approved Key Vault soft-delete retention period."
  type        = number

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "Key Vault soft-delete retention must be between 7 and 90 days."
  }
}
