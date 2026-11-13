terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none" # done in Part A; the Reader plan identity can't register
  storage_use_azuread             = true   # storage accounts have shared keys off
  # subscription_id comes from ARM_SUBSCRIPTION_ID
}