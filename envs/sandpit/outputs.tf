output "resource_group_id" {
  value = data.azurerm_resource_group.sandpit.id
}

output "tags" {
  value = local.tags
}