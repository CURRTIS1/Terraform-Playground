/*

ecr_repository - variables.tf

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
  default     = "400container"
}

variable "repository_name" {
  description = "Name of the ECR Repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Mutability of the image tag"
  type        = string
  default = "MUTABLE"
}

variable "image_scanning" {
  description = "Image scanning on push or manual"
  type        = bool
  default = false
}