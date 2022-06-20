/*

rds_msql - variables.tf

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
  default     = "200data"
}

variable "subnet_group_name" {
  description = "RDS Subnet Group name"
  type        = string
  default     = "myrdssubnetgroup"
}

variable "subnet_ids" {
  description = "Subnets used for the RDS instance"
  type        = list(string)
}

variable "allocated_storage" {
  description = "Storage allocation for the RDS Instance"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type for the RDS Instance"
  type        = string
  default     = "gp2"
}

variable "engine_version" {
  description = "Engine version for the RDS Instance"
  type        = string
}

variable "instance_class" {
  description = "Instance class for the RDS Instance"
  type        = string
  default     = "db.t2.small"
}

variable "name" {
  description = "Name of the RDS Instance"
  type        = string
  default     = "db1"
}

variable "multi_az" {
  description = "Whether Multi-AZ is enabled"
  type        = bool
  default     = true
}

variable "identifier" {
  description = "Identifier for the RDS Instance"
  type        = string
  default     = "database-1-instance-1"
}

variable "port" {
  description = "Port for the RDS Instance"
  type        = number
  default     = 3306
}

variable "username" {
  description = "Username for the RDS Instance"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Password for the RDS Instance"
  type        = string
  default     = "Password"
}

variable "skip_final_snapshot" {
  description = "Whether Skip final snapshot is enabled"
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "Security Groups for the RDS Instance"
  type        = list(string)
}