/*

ecr_repository - outputs.tf

*/

output "ecr_repository" {
  value       = aws_ecr_repository.ecr_repository.name
  description = "The name of the ECR Repository"
}