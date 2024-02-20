/*

key_pair - variables.tf

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
  default     = "300compute"
}

variable "key_name" {
  description = "The name of the Key Pair"
  type        = string
  default     = "MyKP"
}

variable "public_key" {
  description = "The public key for your key pair"
  type        = string
}