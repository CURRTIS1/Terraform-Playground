/*

prometheus_grafana - outputs.tf

*/

output "ecs_cluster" {
  value       = aws_ecs_cluster.Prometheus-ECS-Cluster.name
  description = "Name of the ECS Cluster"
}

output "ecs_service" {
  value       = aws_ecs_service.myecssvcA.name
  description = "Name of the ECS Service"
}