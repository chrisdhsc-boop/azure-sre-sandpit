# v0: insecure on purpose. Each "seed" comment names its Day 6-7 fix.

resource "azurerm_service_plan" "app" {
  name                = "asp-sandpit"
  resource_group_name = data.azurerm_resource_group.sandpit.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "F1"
  tags                = local.tags
}

resource "azurerm_linux_web_app" "app" {
  name                = "app-sandpit-${random_string.sfx.result}"
  resource_group_name = data.azurerm_resource_group.sandpit.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app.id
  https_only          = false # seed 2 -> true
  tags                = local.tags

  site_config {
    always_on  = false        # F1 can't run always-on
    ftps_state = "AllAllowed" # seed 2 -> "Disabled"
    application_stack {
      python_version = "3.10" # seed 2: oldest still offered -> current
    }
  }

  app_settings = {
    # seed 3: password in plain app settings -> managed identity + Key Vault reference
    SQL_CONNECTION = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.db.name};User ID=${azurerm_mssql_server.sql.administrator_login};Password=${random_password.sql.result};Encrypt=true"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-sandpit-${random_string.sfx.result}"
  resource_group_name        = data.azurerm_resource_group.sandpit.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # seed 4 -> true
  # seed 4: no network_acls (open to the internet), access policies instead of RBAC
  tags = local.tags
}

resource "azurerm_key_vault_access_policy" "apply" {
  key_vault_id       = azurerm_key_vault.kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = var.apply_principal_id
  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

resource "azurerm_key_vault_access_policy" "plan" {
  key_vault_id       = azurerm_key_vault.kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = var.plan_principal_id
  secret_permissions = ["Get", "List"]
}
resource "random_password" "sql" {
  length           = 24
  override_special = "!#%*-_"
}

resource "azurerm_mssql_server" "sql" {
  name                         = "sql-sandpit-${random_string.sfx.result}"
  resource_group_name          = data.azurerm_resource_group.sandpit.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = random_password.sql.result
  # seed 5: SQL auth only, no azuread_administrator -> Entra-only auth
  tags = local.tags
}

resource "azurerm_mssql_firewall_rule" "all" {
  name             = "allow-all" # seed 5 -> delete
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_mssql_database" "db" {
  name                        = "sqldb-sandpit"
  server_id                   = azurerm_mssql_server.sql.id
  sku_name                    = "GP_S_Gen5_2"
  max_size_gb                 = 2 # small = cheap storage
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60 # sleeps after 1 h idle: no compute charge
  tags                        = local.tags
}