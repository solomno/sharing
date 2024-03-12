### Ensure none of these resources can be removed anywhere in the platform

data "azurerm_management_group" "dev_workloads" {
  display_name = "Development Workloads"
}

resource "azurerm_management_group_policy_assignment" "deny_actions" {
  name                 = "denyactions"
  display_name         = "[GOV] Disallow deletion of specific resource types"
  description          = "Avoid accidental or malicious deletion of resources by disallowing deletion of specific resource types."
  policy_definition_id = azurerm_policy_definition.policy_definitions["denyactions-nodelete-indexed"].id
  management_group_id  = data.azurerm_management_group.dev_workloads.id
  not_scopes           = []
  enforce              = true

  parameters = jsonencode({
    "protectedResources" : {
      "value" : [
        "Microsoft.RecoveryServices/vaults",
        "Microsoft.ContainerService/managedClusters",
        "Microsoft.ContainerRegistry/registries",
        "Microsoft.Databricks/workspaces",
        "Microsoft.OperationalInsights/workspaces",
        "Microsoft.Network/publicIPAddresses",
        "Microsoft.Network/applicationGateways",
        "Microsoft.Network/virtualWans",
        "Microsoft.Network/virtualHubs",
        "Microsoft.Network/vpnSites",
        "Microsoft.Network/vpnGateways",
        "Microsoft.Network/azureFirewalls",
        "Microsoft.Network/firewallPolicies",
        "Microsoft.Network/privateDnsZones",
        "Microsoft.Network/dnsZones"
      ]
    }
  })
}

### Ensure no SQL LTR backups can be removed

resource "azurerm_management_group_policy_assignment" "deny_actions_all" {
  name                 = "denyactions-all"
  display_name         = "[GOV] Disallow deletion of specific resource types in ALL mode"
  description          = "Avoid accidental or malicious deletion of resources by disallowing deletion of specific resource types."
  policy_definition_id = azurerm_policy_definition.policy_definitions["denyactions-nodelete-all"].id
  management_group_id  = data.azurerm_management_group.dev_workloads.id
  not_scopes           = []
  enforce              = true

  parameters = jsonencode({
    "protectedResources" : {
      "value" : [
        # SQL Server LTR backups are still in place even if the SQL Server and resoruce group is deleted
        "Microsoft.Sql/locations/longTermRetentionServers/longTermRetentionDatabases/longTermRetentionBackups",
        "Microsoft.Sql/locations/longTermRetentionManagedInstances/longTermRetentionDatabases/longTermRetentionManagedInstanceBackups",
      ]
    }
  })
}
