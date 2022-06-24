/*

400container - variables.tf

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

variable "tg_name" {
  description = "Target group name"
  type        = string
}

variable "elb_name" {
  description = "Loadbalancer name"
  type        = string
}

variable "target_type" {
  description = "Target type for the TG"
  type        = string
  default     = "instance"
}

variable "tg_port" {
  description = "port for the TG"
  type        = number
  default     = 80
}

variable "key_name" {
  description = "The name of the Key Pair"
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

variable "ami_id" {
  description = "AMI to create in the ASG"
  type        = string
  default     = ""
}