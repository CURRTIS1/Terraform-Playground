/*

ec2_asg - variables.tf

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

variable "instance_type" {
  description = "Instance type of the ASG instances"
  type        = string
  default     = "t3.small"
}

variable "key_pair" {
  description = "Key pair for the ASG instances"
  type        = string
  default     = ""
}

variable "security_groups" {
  description = "Security groups for the ASG instances"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile of the ASG instances"
  type        = string
}

variable "asg_lt_name" {
  description = "Name of autoscaling group launch template"
  type        = string
  default     = "My-asg-lt"
}

variable "asg_name" {
  description = "Name of autoscaling group"
  type        = string
  default     = "My-asg"
}

variable "autoscale_min" {
  description = "Min num of instances"
  type        = number
  default     = 0
}

variable "autoscale_max" {
  description = "Max num of instances"
  type        = number
  default     = 1
}

variable "target_group_arn" {
  description = "Target group ARN to attach to the ASG"
  type        = list(string)
  default     = null
}

variable "vpc_subnets" {
  description = "VPC subnets to put the ASG instances in"
  type        = list(string)
}

variable "health_check" {
  description = "Health check type for the ASG"
  type        = string
  default     = "EC2"
}

variable "ami_id" {
  description = "AMI for the instances"
  type        = string
  default     = ""
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