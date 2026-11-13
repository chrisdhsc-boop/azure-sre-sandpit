terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateda4bcdca"
    container_name       = "tfstate"
    key                  = "sandpit.tfstate"
    use_azuread_auth     = true
  }
}