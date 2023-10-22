locals {
  policy_definition_files     = fileset("${path.module}/policy_definitions", "*.json")
  raw_data_policy_definitions = [for f in local.policy_definition_files : jsondecode(templatefile("${path.module}/policy_definitions/${f}", local.template_file_vars))]

  root_resource_id = "/providers/Microsoft.Management/managementGroups/MyAzureRootGroup"
  template_file_vars = {
    "root_scope_resource_id"    = local.root_resource_id
    "current_scope_resource_id" = local.root_resource_id
  }
  empty_list = []
}
