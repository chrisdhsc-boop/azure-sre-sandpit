locals {
  tags = { env = "sandpit", owner = var.owner, ttl = var.ttl }
}

data "azurerm_resource_group" "sandpit" {
  name = "rg-sandpit"
}
resource "random_string" "sfx" {
  length  = 6
  special = false
  upper   = false
}

module "storage" {
  source                    = "../../modules/storage"
  name                      = "stsandpit${random_string.sfx.result}"
  resource_group_name       = data.azurerm_resource_group.sandpit.name
  location                  = var.location
  tags                      = local.tags
  allow_public_blobs        = true # seed 1 -> fix: delete line
  shared_access_key_enabled = true # seed 1 -> fix: delete line
}