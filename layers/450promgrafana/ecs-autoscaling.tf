## ----------------------------------
## ECS Schedule Target

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 1
  min_capacity       = 1
  resource_id        = "service/${module.prometheus_grafana.ecs_cluster}/${module.prometheus_grafana.ecs_service}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


## ----------------------------------
## ECS Schedule Scale-In

resource "aws_appautoscaling_scheduled_action" "ecs_up" {
  name               = "ecs_scale_in_for_${module.prometheus_grafana.ecs_service}"
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  schedule           = "cron(00 06 ? * MON-FRI *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }
}


## ----------------------------------
## ECS Schedule Scale-Out

resource "aws_appautoscaling_scheduled_action" "ecs_down" {
  name               = "ecs_scale_down_for_${module.prometheus_grafana.ecs_service}"
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  schedule           = "cron(00 20 ? * MON-FRI *)"

  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}