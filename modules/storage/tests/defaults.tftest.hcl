# modules/storage/tests/defaults.tftest.hcl
mock_provider "azurerm" {}

variables {
  name                = "stsandpittest01"
  resource_group_name = "rg-test"
  location            = "uksouth"
}

run "secure_defaults" {
  command = plan
  assert {
    condition     = azurerm_storage_account.this.min_tls_version == "TLS1_2"
    error_message = "Default TLS must be 1.2"
  }
  assert {
    condition     = azurerm_storage_account.this.allow_nested_items_to_be_public == false
    error_message = "Public blobs must be off by default"
  }
  assert {
    condition     = azurerm_storage_account.this.shared_access_key_enabled == false
    error_message = "Shared keys must be off"
  }
}

run "rejects_bad_name" {
  command = plan
  variables {
    name = "Bad_Name"
  }
  expect_failures = [var.name]
}