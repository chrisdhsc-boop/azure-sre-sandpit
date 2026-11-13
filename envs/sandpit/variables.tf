# tflint-ignore: terraform_unused_declarations # used by the modules from Day 3
variable "location" {
  type    = string
  default = "uksouth"
}
variable "owner" { type = string }
variable "ttl" {
  type        = string
  description = "Teardown date, YYYY-MM-DD"
}
