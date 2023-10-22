

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
