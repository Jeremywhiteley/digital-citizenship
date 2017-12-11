# Terraform configuration file to create Azure resources.
# Set up environment variables before running this script (see README.md)

# Set up an Azure backend to store Terraform state.
# You *must* create the storage account and the container before running this script
terraform {
    backend "azurerm" {
        resource_group_name  = "terraform-resource-group"
        storage_account_name = "terraformstorageaccount"
        container_name       = "terraform-storage-container"
    }
}

# Environment: production, developement or staging
variable environment {
    type = "string"
}

# Location of the Azure resource group and services (ie. West Europe)
variable location {
    type = "string"
}

# Location for CosmosDB failover (ie. North Europe)
# Must differ from "location" value
variable "cosmosdb_failover_location" {
    type = "string"
}

# Name of the resource group
variable "azurerm_resource_group" {
    type = "string"
}

# Name of the storage account
variable "azurerm_storage_account" {
    type = "string"
}

# Name of the storage container resource
variable "azurerm_storage_container" {
    type = "string"
}

# Name of the storage account for functions
variable "azurerm_functionapp_storage_account" {
    type = "string"
}

# Name of the storage queue for email notifications
variable "azurerm_storage_queue_emailnotifications" {
    type = "string"
}

# Name of the storage queue for created messages
variable "azurerm_storage_queue_createdmessages" {
    type = "string"
}

# Name of the CosmosDB account
variable "azurerm_cosmosdb" {
    type = "string"
}

# Name of the App Service Plan resource
variable "azurerm_app_service_plan" {
    type = "string"
}

# Name of the App Service Plan for developer portal
variable "azurerm_app_service_plan_portal" {
    type = "string"
}

# Name of the App Service for developer portal
variable "azurerm_app_service_portal" {
    type = "string"
}

# Name of the API management resource
variable "azurerm_apim" {
    type = "string"
}

# Name of the ADB2C policy
variable "azurerm_adb2c_policy" {
    type = "string"
}

# Name of Application Insights resource
variable "azurerm_application_insights" {
    type = "string"
}

# Name of Log Analytics resource
variable "azurerm_log_analytics" {
    type = "string"
}

# EventHub namespace
variable "azurerm_eventhub_ns" {
    type = "string"
}

# EventHub logger for API management
variable "azurerm_apim_eventhub" {
    type = "string"
}

# EventHub rule for API management
variable "azurerm_apim_eventhub_rule" {
    type = "string"
}

# The name of the Kubernetes cluster resource.
variable "azurerm_container_service_name" {
  type        = "string"
  description = "The name of the Kubernetes cluster resource."
}

# The number of Kubernetes masters in the cluster.
variable "azurerm_container_service_master_count" {
  type        = "string"
  default     = "1"
  description = "The number of Kubernetes master in the cluster. Allowed values are 1, 3, 5. The default value is 1."
}

# The number of Kubernetes linux agents in the cluster.
variable "azurerm_container_service_agent_count" {
  type        = "string"
  default     = "1"
  description = "The number of Kubernetes linux agents in the cluster. Allowed values are 1-100 (inclusive). The default value is 1."
}

# The size of the virtual machine used for the Kubernetes linux agents in the cluster.
# complete, up-to-date list of VM sizes can be found at
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes
variable "azurerm_container_service_agent_vm" {
  type        = "string"
  default     = "Standard_A0"
  description = "The size of the virtual machine used for the Kubernetes linux agents in the cluster."
}

# User name for authentication to the Kubernetes linux agent virtual machines in the cluster.
variable "azurerm_linux_admin_username" {
  type        = "string"
  default     = "kubeadmin" # "admin" is not allowed
  description = "User name for authentication to the Kubernetes linux agent virtual machines in the cluster."
}

# Configure all the linux virtual machines in the cluster with the SSH RSA public key string.
variable "azurerm_linux_admin_ssh_publickey" {
  type        = "string"
  description = "Configure all the linux virtual machines in the cluster with the SSH RSA public key string. The key should include three parts, for example 'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm'"
}

# The client id of the azure service principal used by Kubernetes to interact with Azure APIs.
# Warning: PASS THIS VIA ENV VAR TF_VAR_azurerm_service_principal_client_id
# Note: we can't get the service principal credentials from Terraform, see:
#       https://github.com/terraform-providers/terraform-provider-azurerm/issues/88
variable "azurerm_service_principal_client_id" {
  type        = "string"
  description = "The client id of the azure service principal used by Kubernetes to interact with Azure APIs."
}

# The client secret of the azure service principal used by Kubernetes to interact with Azure APIs.
# Warning: PASS THIS VIA ENV VAR TF_VAR_azurerm_service_principal_client_secret
# Note: All arguments including the client secret will be stored in the raw state as plain-text.
# Read more about sensitive data in state at https://www.terraform.io/docs/providers/azurerm/r/container_service.html
variable "azurerm_service_principal_client_secret" {
  type        = "string"
  description = "The client secret of the azure service principal used by Kubernetes to interact with Azure APIs."
}

# module "variables" {
#     source = "./modules/variables"
# }

## RESOURCE GROUP

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "azurerm_resource_group" {
    name     = "${var.azurerm_resource_group}"
    location = "${var.location}"
    tags {
        environment = "${var.environment}"
    }
}

## STORAGE

resource "azurerm_storage_account" "azurerm_storage_account" {
    name                = "${var.azurerm_storage_account}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
    location            = "${azurerm_resource_group.azurerm_resource_group.location}"

    # can be one between Premium_LRS, Standard_GRS, Standard_LRS, Standard_RAGRS, Standard_ZRS
    # see https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy
    account_tier             = "Standard"
    account_replication_type = "GRS"

    # see https://docs.microsoft.com/en-us/azure/storage/common/storage-service-encryption
    enable_blob_encryption = true

    tags {
        environment = "${var.environment}"
    }
}

resource "azurerm_storage_account" "azurerm_functionapp_storage_account" {
    name                = "${var.azurerm_functionapp_storage_account}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
    location            = "${azurerm_resource_group.azurerm_resource_group.location}"

    # can be one between Premium_LRS, Standard_GRS, Standard_LRS, Standard_RAGRS, Standard_ZRS
    # see https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy
    account_tier             = "Standard"
    account_replication_type = "GRS"

    # see https://docs.microsoft.com/en-us/azure/storage/common/storage-service-encryption
    enable_blob_encryption = true

    tags {
        environment = "${var.environment}"
    }
}

resource "azurerm_storage_container" "azurerm_storage_container" {
    name                    = "${var.azurerm_storage_container}"
    resource_group_name     = "${azurerm_resource_group.azurerm_resource_group.name}"
    storage_account_name    = "${azurerm_storage_account.azurerm_storage_account.name}"

    # Can be either blob (to publish blob on internet),container (to publish everything) or private
    container_access_type   = "private"
}

## QUEUES

resource "azurerm_storage_queue" "azurerm_storage_queue_emailnotifications" {
    name                 = "${var.azurerm_storage_queue_emailnotifications}"
    resource_group_name  = "${azurerm_resource_group.azurerm_resource_group.name}"
    storage_account_name = "${azurerm_storage_account.azurerm_storage_account.name}"
}

resource "azurerm_storage_queue" "azurerm_storage_queue_createdmessages" {
    name                 = "${var.azurerm_storage_queue_createdmessages}"
    resource_group_name  = "${azurerm_resource_group.azurerm_resource_group.name}"
    storage_account_name = "${azurerm_storage_account.azurerm_storage_account.name}"
}

## DATABASE

resource "azurerm_cosmosdb_account" "azurerm_cosmosdb" {
    name                = "${var.azurerm_cosmosdb}"
    location            = "${azurerm_resource_group.azurerm_resource_group.location}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"

    # Possible values are GlobalDocumentDB and MongoDB
    kind = "GlobalDocumentDB"

    # Required - can be only set to Standard
    offer_type          = "Standard"

    # Can be either BoundedStaleness, Eventual, Session or Strong
    # see https://docs.microsoft.com/en-us/azure/cosmos-db/consistency-levels
    # Note: with the default BoundedStaleness settings CosmosDB cannot perform failover / replication:
    #   Operations (max_staleness): for a single region the maximum operations lag must be between 10 and 1 000 000
    #               for the multi region, it will be between 100 000 and 1 000 000
    #   Time (max_interval_in_seconds): the maximum lag must be between 5 seconds and 1 day for either single or multi-regions
    consistency_policy {
        consistency_level = "Session"
    }

    failover_policy {
        location = "${var.cosmosdb_failover_location}"
        priority = 0
    }

    tags {
        environment = "${var.environment}"
    }

    ## !!! DATABASE AND COLLECTIONS ARE NOT SUPPORTED: we create them manually
    # provisioner "local-exec" {
    #   command = "ts-node ./tasks/cosmosdb.ts"
    # }
}

## APPLICATION INSIGHTS

resource "azurerm_application_insights" "azurerm_application_insights" {
    name                = "${var.azurerm_application_insights}"
    location            = "${azurerm_resource_group.azurerm_resource_group.location}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
    # Web or Other
    application_type    = "Web"
}

## APP SERVICE PLAN

resource "azurerm_app_service_plan" "azurerm_app_service_plan" {
    name                = "${var.azurerm_app_service_plan}"
    location            = "${azurerm_resource_group.azurerm_resource_group.location}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"

    sku {
        tier = "Standard"
        # Possible values are B1, B2, B3, D1, F1, FREE, P1, P2, P3, S1, S2, S3, SHARED
        size = "S1"
    }

    ## !!! FUNCTIONS APP ARE NOT SUPPORTED: we create them manually
    # provisioner "local-exec" {
    #    command = "ts-node ./tasks/functions.ts"
    # }
}

### DEVELOPER PORTAL TASKS

resource "azurerm_app_service_plan" "azurerm_app_service_plan_portal" {
    name                = "${var.azurerm_app_service_plan_portal}"
    location            = "${azurerm_resource_group.azurerm_resource_group.location}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"

    sku {
        tier = "Standard"
        # Possible values are B1, B2, B3, D1, F1, FREE, P1, P2, P3, S1, S2, S3, SHARED
        size = "S1"
    }
}

resource "random_string" "cookie_key" {
  length = 32
}

resource "random_string" "cookie_iv" {
  length = 12
}

resource "azurerm_app_service" "azurerm_app_service_portal" {
    name                = "${var.azurerm_app_service_portal}"
    location            = "${azurerm_resource_group.azurerm_resource_group.location}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
    app_service_plan_id = "${azurerm_app_service_plan.azurerm_app_service_plan_portal.id}"

    site_config {
        always_on = true
    }

    # Go to https://github.com/teamdigitale/digital-citizenship-onboarding
    # to see how to fill these values
    app_settings {
        ARM_SUBSCRIPTION_ID = ""
        ADMIN_API_KEY = ""
        CLIENT_ID = ""
        CLIENT_SECRET = ""
        POLICY_NAME = "${var.azurerm_adb2c_policy}"
        WEBSITE_NODE_DEFAULT_VERSION = "6.5.0"
        COOKIE_KEY = "${random_string.cookie_key.result}"
        COOKIE_IV = "${random_string.cookie_iv.result}"
        LOG_LEVEL = "info"
        ARM_RESOURCE_GROUP = "${azurerm_resource_group.azurerm_resource_group.name}"
        ARM_APIM = "${var.azurerm_apim}"
        APIM_PRODUCT_NAME = "starter"
        APIM_USER_GROUPS = "ApiLimitedMessageWrite,ApiInfoRead,ApiMessageRead"
        ADMIN_API_URL = "https://${var.azurerm_apim}.azure-api.net/"
        POST_LOGIN_URL = "https://${var.azurerm_apim}.portal.azure-api.net/developer"
        POST_LOGOUT_URL = "https://${var.azurerm_apim}.portal.azure-api.net/"
        REPLY_URL = "https://${var.azurerm_app_service_portal}.azurewebsites.net/auth/openid/return"
    }
}

# TODO: assign role to the MSI to let the App Service access API Management users
# resource "azurerm_virtual_machine_extension" "app_service_portal_msi" {
#     name                 = "app_service_portal_msi"
#     location            = "${azurerm_resource_group.azurerm_resource_group.location}"
#     resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
#     app_service_plan_id = "${azurerm_app_service_plan.azurerm_app_service_plan_portal.id}"
#
#     # virtual_machine_name = "${azurerm_virtual_machine.test.name}"
#
#     publisher            = "Microsoft.ManagedIdentity"
#     type                 = "ManagedIdentityExtensionForWindows"
#     type_handler_version = "1.0"
#     settings             = ""
# }
# resource "azurerm_role_assignment" "app_service_portal_role" {
#   name               = "app_service_portal_role"
#   scope              = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.azurerm_resource_group}/providers/Microsoft.Storage/storageAccounts/${var.azurerm_apim}"
#   role_definition_id = ""
#   principal_id       = ""
# }

## !!! API MANAGER NOT SUPPORTED

# Logging (OSM)

resource "azurerm_log_analytics_workspace" "azurerm_log_analytics" {
    name                = "${var.azurerm_log_analytics}"
    location            = "${azurerm_resource_group.azurerm_resource_group.location}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
    sku                 = "Standard"
    retention_in_days   = 30
}

# Logging (EventHub)

resource "azurerm_eventhub_namespace" "azurerm_eventhub_ns" {
    name                = "${var.azurerm_eventhub_ns}"
    location            = "${azurerm_resource_group.azurerm_resource_group.location}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
    sku                 = "Standard"
    capacity            = 1
    tags {
        environment = "${var.environment}"
    }
}

resource "azurerm_eventhub" "azurerm_apim_eventhub" {
    name                = "${var.azurerm_apim_eventhub}"
    namespace_name      = "${azurerm_eventhub_namespace.azurerm_eventhub_ns.name}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
    # EventHub Partition Count has to be between 2 and 32
    partition_count     = 2
    message_retention   = 7
}

resource "azurerm_eventhub_authorization_rule" "azurerm_apim_eventhub_rule" {
    name                = "${var.azurerm_apim_eventhub_rule}"
    namespace_name      = "${azurerm_eventhub_namespace.azurerm_eventhub_ns.name}"
    resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
    eventhub_name       = "${azurerm_eventhub.azurerm_apim_eventhub.name}"
    listen              = true
    send                = true
    manage              = false
}

# Azure Container Service (Kubernetes)

resource "azurerm_container_service" "azurerm_container_service" {
  name                   = "${var.azurerm_container_service_name}"
  location               = "${azurerm_resource_group.azurerm_resource_group.location}"
  resource_group_name    = "${azurerm_resource_group.azurerm_resource_group.name}"
  orchestration_platform = "Kubernetes"

  master_profile {
    count      = "${var.azurerm_container_service_master_count}" // 3 or 5 for HA
    dns_prefix = "${var.azurerm_container_service_name}-master"
  }

  linux_profile {
    admin_username = "${var.azurerm_linux_admin_username}"

    ssh_key {
      key_data = "${var.azurerm_linux_admin_ssh_publickey}"
    }
  }

  agent_pool_profile {
    name       = "default"
    count      = "${var.azurerm_container_service_agent_count}"
    dns_prefix = "${var.azurerm_container_service_name}-agent"
    vm_size    = "${var.azurerm_container_service_agent_vm}"
  }

  service_principal {
    client_id     = "${var.azurerm_service_principal_client_id}"
    client_secret = "${var.azurerm_service_principal_client_secret}"
  }

  diagnostics_profile {
    enabled = false
  }

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_public_ip" "azurerm_public_ip_container_service" {
  name                         = "${var.azurerm_container_service_name}-publicip"
  location                     = "${azurerm_resource_group.azurerm_resource_group.location}"
  resource_group_name          = "${azurerm_resource_group.azurerm_resource_group.name}"
  public_ip_address_allocation = "static"

  # reverse_fqdn

  tags {
    environment = "${var.environment}"
  }
}

# The allocated static IP must be set in loadBalancerIP in the ingress config
# of the Kubernetes cluster
# See https://kubernetes.io/docs/concepts/services-networking/service/#type-loadbalancer
output "azurerm_public_ip_container_service_ip" {
  value = "${azurerm_public_ip.azurerm_public_ip_container_service.ip_address}"
}
