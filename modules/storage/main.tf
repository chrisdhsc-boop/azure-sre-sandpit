resource "azurerm_storage_account" "this" {
  #checkov:skip=CKV_AZURE_206:LRS is enough for a sandpit; GRS costs more
  #checkov:skip=CKV2_AZURE_1:Microsoft-managed keys; CMK needs Key Vault and adds cost
  #checkov:skip=CKV_AZURE_33:No queues used in this module
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_public_blobs
  shared_access_key_enabled       = false
  https_traffic_only_enabled      = true
  tags                            = var.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}