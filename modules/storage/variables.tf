variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "3-24 lowercase letters and digits."
  }
}
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "min_tls_version" {
  type    = string
  default = "TLS1_2"
}
variable "allow_public_blobs" {
  type    = bool
  default = false
}
variable "shared_access_key_enabled" {
  type    = bool
  default = false
}