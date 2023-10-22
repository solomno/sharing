data "azuread_group" "contributors" {
  display_name = "az rbac sub tstsp1 owners"
}


# This code is run by "User A" - which has unrestricted owner access
# role assignment and condition are created as expected.

resource "azurerm_role_assignment" "tstsp1_constrained" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "User Access Administrator"
  principal_id         = data.azuread_group.contributors.object_id
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

# The below code is run by "User B" - which is a member of the "owners" group
# This works as expected (403- ... does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write')
# Modifying the ABAC condition may give another error code referencing ABAC constraints, which is fine

resource "azurerm_role_assignment" "example_expected_not_to_work" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Owner"
  principal_id         = data.azuread_group.owners.object_id
}


# The below code is run by "User B" - which is a member of the "owners" group
# This example currently does not work as expected, returns (403- ... does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write')
# Assigning the same role in the azure portal does work, so it is likely a missing feature in the azurerm provider
resource "azurerm_role_assignment" "example_expected_to_work" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = data.azuread_group.owners.object_id
}
