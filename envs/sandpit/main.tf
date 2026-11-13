locals {
  tags = { env = "sandpit", owner = var.owner, ttl = var.ttl }
}

data "azurerm_resource_group" "sandpit" {
  name = "rg-sandpit"
}
