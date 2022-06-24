/*

ec2_test_linux - variables.tf

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

variable "linuxtest_subnet_id" {
  description = "Subnet for the instance"
  type        = string
}

variable "linuxtest_vpc_security_group_ids" {
  description = "Security groups for the instance"
  type        = list(string)
}

variable "linuxtest_iam_instance_profile" {
  description = "IAM profile for the instance"
  type        = string
  default     = ""
}

variable "linuxtest_instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.small"
}

variable "linuxtest_key_name" {
  description = "Key pair for the instance"
  type        = string
  default = ""
}

variable "linuxtest_instance_name" {
  description = "Name of the instance"
  type        = string
  default     = "Linux-Test"
}