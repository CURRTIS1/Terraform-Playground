/*

ssm_role - variables.tf

*/

variable "region" {
  description = "The region we are building into."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Build environment"
  type        = string
  default     = "Development"
}

variable "layer" {
  description = "Terraform layer"
  type        = string
  default     = "000Base"
}

variable "ssm_role_name" {
  description = "Name for the SSM role"
  type        = string
  default     = "ssm_role"
}

variable "ssm_profile_name" {
  description = "Name for the SSM profile"
  type        = string
  default     = "ssm_profile"
}