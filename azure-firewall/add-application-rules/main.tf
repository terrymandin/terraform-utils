
variable "firewall_name" {
  description = "Name of the Azure Firewall"
  type        = string
}

variable "firewall_policy_name" {
  description = "Name of the Azure Firewall Policy"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "rule_collection_group_name" {
  description = "Name of the Rule Collection Group"
  type        = string
}

# Untested
resource "azurerm_firewall_policy_rule_collection_group" "arc_urls" {
  name               = var.rule_collection_group_name
  firewall_policy_id = data.azurerm_firewall_policy.fwp_odaa_tm2.id
  priority           = 100

  application_rule_collection {
    name     = "AzureArcApplicationRules"
    priority = 100
    action   = "Allow"

    dynamic "rule" {
      for_each = toset([
        "download.microsoft.com",
        "packages.microsoft.com",
        "login.microsoftonline.com",
        "*.login.microsoft.com",
        "pas.windows.net",
        "management.azure.com",
        "*.his.arc.azure.com",
        "*.guestconfiguration.azure.com",
        "guestnotificationservice.azure.com",
        "*.guestnotificationservice.azure.com",
        "*.servicebus.windows.net",
        "*.waconazure.com",
        "*.blob.core.windows.net",
        "dc.services.visualstudio.com",
        "*.arcdataservices.com",
        "www.microsoft.com",
        "dls.microsoft.com",
        "yum.oracle.com" # Required for ODAA only
      ])
      content {
        name             = "Allow-${replace(replace(rule.value, "*", "wildcard"), ".", "-")}"
        source_addresses = ["*"]
        dynamic "protocols" {
          for_each = rule.value == "www.microsoft.com" ? [
            { type = "Https", port = 443 },
            { type = "Http", port = 80 }
            ] : [
            { type = "Https", port = 443 }
          ]
          content {
            type = protocols.value.type
            port = protocols.value.port
          }
        }
        destination_fqdn_tags = []
        destination_fqdns     = [rule.value]
      }
    }
  }
}


data "azurerm_firewall_policy" "fwp_odaa_tm2" {
  name                = var.firewall_policy_name
  resource_group_name = var.resource_group_name
}

data "azurerm_firewall" "fw_odaa_tm" {
  name                = var.firewall_name
  resource_group_name = var.resource_group_name
}