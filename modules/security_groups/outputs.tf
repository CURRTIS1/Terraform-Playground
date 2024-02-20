/*

security_groups - outputs.tf

*/

output "sg_web" {
  value       = aws_security_group.sg_web.id
  description = "The ID of the WebServer Group"
}

output "sg_rds" {
  value       = aws_security_group.sg_rds.id
  description = "The ID of the RDS Group"
}

output "sg_alb" {
  value       = aws_security_group.sg_alb.id
  description = "The ID of the RDS Group"
}

output "sg_testing" {
  value       = aws_security_group.sg_testing.id
  description = "The ID of the Testing Group"
}

output "sg_ecs" {
  value       = aws_security_group.sg_ecs.id
  description = "The ID of the ECS Group"
}