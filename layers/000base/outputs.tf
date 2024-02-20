/*

000base - outputs.tf

*/

output "vpc_id" {
  value       = module.vpc_basenetwork.vpc_id
  description = "The ID of the main VPC"
}

output "subnet_public" {
  value       = module.vpc_basenetwork.subnet_public
  description = "The ID of the public subnet"
}

output "subnet_private" {
  value       = module.vpc_basenetwork.subnet_private
  description = "The ID of the public subnet"
}

output "ssm_profile" {
  value       = module.ssm_role.ssm_profile
  description = "The ID of the ssm profile"
}

output "ssm_role_name" {
  value       = module.ssm_role.ssm_role_name
  description = "The name of the ssm profile"
}