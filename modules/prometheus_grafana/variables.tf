/*

prometheus_grafana - variables.tf

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

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
  type        = string
}

variable "vpc_id" {
  description = "VPC hosting the ECS service"
  type        = string
}

variable "efs_subnet_id1" {
  description = "ID of the subnet for EFS Mount 1"
  type        = string
}

variable "efs_subnet_id2" {
  description = "ID of the subnet for EFS Mount 2"
  type        = string
}

variable "ecs_subnet_id1" {
  description = "ID of the subnet for Test ECS Service 1"
  type        = list(string)
}

variable "ecs_subnet_id2" {
  description = "ID of the subnet for Test ECS Service 2"
  type        = list(string)
}