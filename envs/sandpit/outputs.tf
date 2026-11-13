output "resource_group_id" {
  value = data.azurerm_resource_group.sandpit.id
}

output "tags" {
  value = local.tags
}
output "app_url" {
  value = "http://${azurerm_linux_web_app.app.default_hostname}"
}

output "storage_account_name" {
  value = module.storage.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql.name
}
