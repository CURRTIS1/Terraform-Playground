/*

200data - variables.tf

*/

variable "region" {
  description = "The region are building into."
  type        = string
}

variable "environment" {
  description = "Build environment"
  type        = string
}

variable "layer" {
  description = "Terraform layer"
  type        = string
}

variable "engine_version" {
  description = "Engine version for the RDS Instance"
  type        = string
}

variable "password" {
  description = "Password for the RDS Instance"
  type        = string
}