/*

Module - prometheus_grafana

This module is used to create Security groups


Usage:

module "prometheus_grafana" {
    source = "../../modules/prometheus_grafana"

}

*/


terraform {
  required_version = "1.2.1"
}

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}

data "aws_caller_identity" "current" {
}


## ----------------------------------
## ECS Service Security Group

resource "aws_security_group" "sg_ECSS" {
  name        = "ECS Service Security Group"
  description = "ECS Service Security Group"
  vpc_id      = var.vpc_id
  ingress {
    description = "Port 8080 from the WebServer"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags, {
      "Name" = "ECS Service Security Group"
    }
  )
}


## ----------------------------------
## Prometheus Service Security Group

resource "aws_security_group" "sg_ECSP" {
  name        = "Prometheus Security Group"
  description = "Prometheus Security Group"
  vpc_id      = var.vpc_id
  ingress {
    description = "Port 9090 from the WebServer"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags, {
      "Name" = "Prometheus Security Group"
    }
  )
}


## ----------------------------------
## Prometheus Execution Role

resource "aws_iam_role" "prometheus-execution-role" {
  name               = "tf-prometheus-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssmrole_attach" {
  role       = aws_iam_role.prometheus-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


## ----------------------------------
## Prometheus Role

resource "aws_iam_role" "prometheus-role" {
  name               = "tf-prometheus-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_policy" "policy_ecs" {
  name = "policy_ecs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ecs:ListClusters", "ecs:ListTasks", "ecs:DescribeTask", "ec2:DescribeInstances", "ecs:DescribeContainerInstances", "ecs:DescribeTasks", "ecs:DescribeTaskDefinition"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        "Action" : ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite"]
        "Effect" : "Allow",
        "Resource" : "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${aws_efs_file_system.prometheus_efs.id}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_role_attach" {
  role       = aws_iam_role.prometheus-role.name
  policy_arn = aws_iam_policy.policy_ecs.arn
}


## ----------------------------------
## ECS Cluster

resource "aws_ecs_cluster" "Prometheus-ECS-Cluster" {
  name = "My-Prometheus-Cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}


## ----------------------------------
## ECS Namespace

resource "aws_service_discovery_private_dns_namespace" "ECS_Namespace" {
  name        = "local"
  description = "ECS_Namespace"
  vpc         = var.vpc_id
}


## ----------------------------------
## ECS Log Group

resource "aws_cloudwatch_log_group" "ECS_Log_Group" {
  name              = "prometheus-ecs"
  retention_in_days = 7
}


## ----------------------------------
## Prometheus EFS

resource "aws_efs_file_system" "prometheus_efs" {
  creation_token = "prometheus-efs"
  encrypted      = true

  tags = {
    Name = "prometheus-data"
  }
}

## ----------------------------------
## Prometheus EFS Mount Target 1

resource "aws_efs_mount_target" "efsmount1" {
  file_system_id  = aws_efs_file_system.prometheus_efs.id
  subnet_id       = var.efs_subnet_id1
  security_groups = [aws_security_group.sg_EFS.id]
}

## ----------------------------------
## Prometheus EFS Mount Target 2

resource "aws_efs_mount_target" "efsmount2" {
  file_system_id  = aws_efs_file_system.prometheus_efs.id
  subnet_id       = var.efs_subnet_id2
  security_groups = [aws_security_group.sg_EFS.id]
}


## ----------------------------------
## Prometheus EFS Access Point Outputs

resource "aws_efs_access_point" "efs_access_outputs" {
  file_system_id = aws_efs_file_system.prometheus_efs.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/prometheus-outputs"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
}

## ----------------------------------
## Prometheus EFS Access Point Outputs

resource "aws_efs_access_point" "efs_access_metrics" {
  file_system_id = aws_efs_file_system.prometheus_efs.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/prometheus-metrics"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
}


## ----------------------------------
## EFS Security Group

resource "aws_security_group" "sg_EFS" {
  name        = "EFS Security Group"
  description = "EFS Security Group"
  vpc_id      = var.vpc_id
  ingress {
    description     = "Port 2049 from the Prometheus"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_ECSP.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags, {
      "Name" = "EFS Security Group"
    }
  )
}


## ----------------------------------
## ECS Prometheus Task definition

resource "aws_ecs_task_definition" "myprometheustaskdef" {
  family                   = "sample-metrics-application-task"
  requires_compatibilities = ["EC2", "FARGATE"]
  memory                   = 512
  cpu                      = 256
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    {
      name      = "sample-metrics-application"
      image     = "tkgregory/sample-metrics-application"
      essential = true
      "dockerLabels" : {
        "PROMETHEUS_EXPORTER_PATH" : "/actuator/prometheus",
        "PROMETHEUS_EXPORTER_PORT" : "8080"
      }
      portMappings = [
        {
          containerPort = 8080
        }
      ]
    }
  ])
}

data "aws_ecs_container_definition" "ecs-prometheus" {
  task_definition = aws_ecs_task_definition.myprometheustaskdef.id
  container_name  = "sample-metrics-application"
}


## ----------------------------------
## ECS Service A

resource "aws_ecs_service" "myecssvcA" {
  name            = "Test-ECS-Service1"
  cluster         = aws_ecs_cluster.Prometheus-ECS-Cluster.id
  task_definition = aws_ecs_task_definition.myprometheustaskdef.id
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.ecs_subnet_id1
    security_groups  = [aws_security_group.sg_ECSS.id]
    assign_public_ip = true
  }
}


## ----------------------------------
## ECS Service B

resource "aws_ecs_service" "myecssvcB" {
  name            = "Test-ECS-Service2"
  cluster         = aws_ecs_cluster.Prometheus-ECS-Cluster.id
  task_definition = aws_ecs_task_definition.myprometheustaskdef.id
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.ecs_subnet_id2
    security_groups  = [aws_security_group.sg_ECSS.id]
    assign_public_ip = true
  }
}

## ----------------------------------
## ECS Prometheus discovery Task definition with EFS

resource "aws_ecs_task_definition" "myprometheustaskdef2" {
  family                   = "prometheus-for-ecs"
  memory                   = 512
  cpu                      = 256
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2", "FARGATE"]
  execution_role_arn       = aws_iam_role.prometheus-execution-role.arn
  task_role_arn            = aws_iam_role.prometheus-role.arn
  volume {
    name = "prometheus-data-output"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.prometheus_efs.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.efs_access_outputs.id
        iam             = "ENABLED"
      }
    }
  }
  volume {
    name = "prometheus-data-metrics"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.prometheus_efs.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.efs_access_metrics.id
        iam             = "ENABLED"
      }
    }
  }
  container_definitions = jsonencode([
    {
      name  = "prometheus-for-ecs"
      image = "tkgregory/prometheus-with-remote-configuration:latest"
      portMappings = [
        {
          containerPort = 9090
        }
      ]
      "environment" : [
        { "name" : "CONFIG_LOCATION", "value" : "https://tomgregory-cloudformation-resources.s3-eu-west-1.amazonaws.com/prometheus.yml" }
      ]
      "MountPoints" = [
        {
          SourceVolume  = "prometheus-data-output"
          ContainerPath = "/output"
        },
        {
          SourceVolume  = "prometheus-data-metrics"
          ContainerPath = "/prometheus"
        }
      ]
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "prometheus-ecs",
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "prometheus-for-ecs"
        }
      }
    },
    {
      name  = "prometheus-ecs-discovery"
      image = "tkgregory/prometheus-ecs-discovery:latest"
      "environment" : [
        { "name" : "AWS_REGION", "value" : "us-east-1" }
      ]
      "MountPoints" = [
        {
          SourceVolume  = "prometheus-data-output"
          ContainerPath = "/output"
        },
        {
          SourceVolume  = "prometheus-data-metrics"
          ContainerPath = "/prometheus"
        }
      ]
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "prometheus-ecs",
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "prometheus-ecs-discovery"
        }
      }
      "command" : [
        "-config.write-to=/output/ecs_file_sd.yml"
      ]
    }
  ])
}

## ----------------------------------
## ECS Service Prometheus

resource "aws_ecs_service" "myecssvcProm" {
  name            = "Prometheus"
  cluster         = aws_ecs_cluster.Prometheus-ECS-Cluster.id
  task_definition = aws_ecs_task_definition.myprometheustaskdef2.id
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.ecs_subnet_id1
    security_groups  = [aws_security_group.sg_ECSP.id]
    assign_public_ip = true
  }
}

## ----------------------------------
## Grafana Security Group

resource "aws_security_group" "sg_Grafana" {
  name        = "Grafana Security Group"
  description = "Grafana Security Group"
  vpc_id      = var.vpc_id
  ingress {
    description = "Port 8080 from the WebServer"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags, {
      "Name" = "Grafana Security Group"
    }
  )
}


## ----------------------------------
## Grafana Task definition

resource "aws_ecs_task_definition" "grafanataskdef" {
  family                   = "grafana-fargate-demo"
  requires_compatibilities = ["EC2", "FARGATE"]
  memory                   = 512
  cpu                      = 256
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.prometheus-execution-role.arn
  container_definitions = jsonencode([
    {
      name      = "grafana-container"
      image     = "grafana/grafana"
      essential = true
      portMappings = [
        {
          containerPort = 3000
        }
      ]
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "prometheus-ecs",
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "grafana-for-ecs"
        }
      }
    }
  ])
}

## ----------------------------------
## ECS Service Grafana

resource "aws_ecs_service" "myecssvcGrafana" {
  name            = "Grafana"
  cluster         = aws_ecs_cluster.Prometheus-ECS-Cluster.id
  task_definition = aws_ecs_task_definition.grafanataskdef.id
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.ecs_subnet_id1
    security_groups  = [aws_security_group.sg_Grafana.id]
    assign_public_ip = true
  }
}