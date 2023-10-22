resource "azurerm_policy_definition" "policy_definitions" {
  for_each = { for f in local.raw_data_policy_definitions : f.name => f }

  # Mandatory resource attributes
  name         = each.value.name
  policy_type  = "Custom"
  mode         = each.value.properties.mode
  display_name = each.value.properties.displayName

  # Optional resource attributes
  description         = try(each.value.properties.description, "${each.value.name} Policy Definition at scope ${data.azurerm_management_group.dev_workloads.id}")
  management_group_id = local.root_resource_id
  policy_rule         = try(length(each.value.properties.policyRule) > 0, false) ? jsonencode(each.value.properties.policyRule) : null
  metadata            = try(length(each.value.properties.metadata) > 0, false) ? jsonencode(each.value.properties.metadata) : null
  parameters          = try(length(each.value.properties.parameters) > 0, false) ? jsonencode(each.value.properties.parameters) : null
}
