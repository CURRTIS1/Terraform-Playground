/*

ssm_role - outputs.tf

*/

output "ssm_profile" {
  value       = aws_iam_instance_profile.ssm_profile.id
  description = "The ID of the ssm profile"
}

output "ssm_role_name" {
  value       = aws_iam_role.ssm_role.name
  description = "The name of the ssm profile"
}

output "ssm_role_arn" {
  value       = aws_iam_role.ssm_role.arn
  description = "The arn of the ssm profile"
}