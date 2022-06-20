/*

100security - outputs.tf

*/

output "sg_web" {
  value       = module.security_groups.sg_web
  description = "The ID of the WebServer Group"
}

output "sg_rds" {
  value       = module.security_groups.sg_rds
  description = "The ID of the RDS Group"
}

output "sg_alb" {
  value       = module.security_groups.sg_alb
  description = "The ID of the RDS Group"
}

output "sg_testing" {
  value       = module.security_groups.sg_testing
  description = "The ID of the Testing Group"
}

output "sg_ecs" {
  value       = module.security_groups.sg_ecs
  description = "The ID of the ECS Group"
}