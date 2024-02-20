/*

300compute - variables.tf

*/

variable "region" {
  description = "The region we are building into."
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

variable "key_name" {
  description = "The name of the Key Pair"
  type        = string
}

variable "windowstest_instance_name" {
  description = "Name of the instance"
  type        = string
}

variable "windowstest_instance_type" {
  description = "Instance type"
  type        = string
}

variable "linuxtest_instance_name" {
  description = "Name of the instance"
  type        = string
}

variable "linuxtest_instance_type" {
  description = "Instance type"
  type        = string
}

variable "tg_name" {
  description = "Name of the target group"
  type        = string
}

variable "elb_name" {
  description = "Name of the Loadbalancer"
  type        = string
}

variable "asg_instance_type" {
  description = "Instance type for the ASG instances"
  type        = string
}

variable "pre_user_data_commands" {
  description = "Script to be ran at the start of the user_data bootstrap"
  type        = string
  default     = ""
}

variable "post_user_data_commands" {
  description = "Script to be ran at the end of the user_data bootstrap"
  type        = string
  default     = ""
}