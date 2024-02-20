# prometheus_grafana
Terraform prometheus_grafana module

This module creates an isolated ECS cluster with test ECS services and an ECS service for both Prometheus and Grafana

The following variables are required when calling the module:

Variable | Description | Value
-------- | ----------- | -----
"vpc_id" | VPC for the ECS Service | string
"efs_subnet_id1" | ID of the subnet for EFS Mount 1 | string
"efs_subnet_id2" | ID of the subnet for EFS Mount 2 | string
"ecs_subnet_id1" | ID of the subnet for Test ECS Service 1 | list(string)
"ecs_subnet_id2" | ID of the subnet for Test ECS Service 2 | list(string)
"aws_access_key" | AWS Access key | string
"aws_secret_key" | AWS Access key | string

### In order access Prometheus and Grafana

#### Prometheus
```
http://<public-ip>:9090
```

#### Grafana
```
http://<public-ip>:3000
```