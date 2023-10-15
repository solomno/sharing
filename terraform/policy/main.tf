locals {
  policy_definition_files       = fileset("${path.module}/policy_definitions", "*.json")
  raw_data_policy_definitions   = [for f in local.policy_definition_files : jsondecode(templatefile("${path.module}/policy_definitions/${f}", local.template_file_vars))]

  root_resource_id = "/providers/Microsoft.Management/managementGroups/MyAzureRootGroup"
  template_file_vars = {
    "root_scope_resource_id"    = local.root_resource_id
    "current_scope_resource_id" = local.root_resource_id
  }
}


resource "azurerm_role_definition" "role_definitions" {
  for_each = { for f in local.raw_data_policy_definitions : f.name => f }

  role_definition_id = basename(each.key)

  name  = each.value.properties.roleName
  scope = local.root_resource_id

  permissions {
    actions          = try(each.value.properties.permissions[0].actions, local.empty_list)
    not_actions      = try(each.value.properties.permissions[0].notActions, local.empty_list)
    data_actions     = try(each.value.properties.permissions[0].dataActions, local.empty_list)
    not_data_actions = try(each.value.properties.permissions[0].notDataActions, local.empty_list)
  }

  # Optional resource attributes
  description       = try(each.value.properties.description, "${each.value.properties.roleName} Role Definition at scope ${local.root_resource_id}")
  assignable_scopes = try(length(each.value.properties.assignableScopes) > 0, false) ? each.value.properties.assignableScopes : [local.root_resource_id, ]

}
