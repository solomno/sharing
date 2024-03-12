locals {
  # Map of roles which the "owners" group should be able to assign to Service Principals and specific Groups
  delegated_roles = {
    "Storage Queue Data Contributor"       = "974c5e8b-45b9-4653-ba55-5f855dd0fb88"
    "Storage Queue Data Message Sender"    = "c6a89b2d-59bc-44d0-9896-0f6e12d7b80a"
    "Storage Queue Data Reader"            = "19e7f393-937e-4f77-808e-94535e297925"
    "Storage Queue Data Message Processor" = "974c5e8b-45b9-4653-ba55-5f855dd0fb88"
  }
  delegated_role_ids_string = join(", ", values(local.delegated_roles))
  # map of groups which can be assigned the roles listed above
  delegated_groups = {
    "contributors" = data.azuread_group.contributors.object_id
  }
  delegated_group_ids_string = join(", ", values(local.delegated_groups))
  workload                   = "tstsp1"
}

data "azuread_group" "owners" {
  display_name = "az rbac sub ${local.workload} owners"
}

data "azuread_group" "contributors" {
  display_name = "az rbac sub ${local.workload} contributors"
}


# This code is run by "User A" - which has unrestricted owner access
# role assignment and condition are created as expected.

resource "azurerm_role_assignment" "tstsp1_constrained" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "User Access Administrator"
  principal_id         = data.azuread_group.owners.object_id
  principal_type       = "Group"
  description          = "This role assignment is used to allow the owners group to assign the delegated roles to the delegated groups"
  condition_version    = "2.0"
  condition            = <<-EOT
(
 (
  !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
 )
 OR 
 (
  @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.delegated_role_ids_string}}
  AND
  (
   @Request[Microsoft.Authorization/roleAssignments:PrincipalType] StringEqualsIgnoreCase 'ServicePrincipal'
   OR
   @Request[Microsoft.Authorization/roleAssignments:PrincipalType] StringEqualsIgnoreCase 'Group'
   AND
   @Request[Microsoft.Authorization/roleAssignments:PrincipalId] ForAnyOfAnyValues:GuidEquals {${local.delegated_group_ids_string}}
  )
 )
)
AND
(
 (
  !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
 )
 OR 
 (
  @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.delegated_role_ids_string}}
  AND
  (
   @Resource[Microsoft.Authorization/roleAssignments:PrincipalType] StringEqualsIgnoreCase 'ServicePrincipal'
   OR
   @Resource[Microsoft.Authorization/roleAssignments:PrincipalType] StringEqualsIgnoreCase 'Group'
   AND
   @Resource[Microsoft.Authorization/roleAssignments:PrincipalId] ForAnyOfAnyValues:GuidEquals {${local.delegated_group_ids_string}}
  )
 )
)
EOT
}

data "azurerm_subscription" "current" {}

# Run by "User B"
# Should not work due to ABAC constraint
resource "azurerm_role_assignment" "example_expected_not_to_work" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Owner"
  principal_type       = "Group"
  principal_id         = data.azuread_group.owners.object_id
}

# Run by "User B"
# Should work as long as   principal_type       = "Group" is explicitly set.
resource "azurerm_role_assignment" "example_expected_to_work" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = data.azuread_group.owners.object_id
  principal_type       = "Group"
}
