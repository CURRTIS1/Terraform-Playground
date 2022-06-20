/*

350container - main.tf

Required layers:
000base
100security

Required modules:

*/

terraform {
  required_version = "1.2.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.15.0"
    }
  }

  backend "s3" {
    bucket  = "curtis-terraform-test-2020"
    key     = "terraform.350container.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}


data "terraform_remote_state" "state_000base" {
  backend = "s3"
  config = {
    bucket = "curtis-terraform-test-2020"
    key    = "terraform.000base.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "state_100security" {
  backend = "s3"
  config = {
    bucket = "curtis-terraform-test-2020"
    key    = "terraform.100security.tfstate"
    region = "us-east-1"
  }
}


data "aws_caller_identity" "current" {
}


## ----------------------------------
## ECS attachment

resource "aws_iam_role_policy_attachment" "ecs_ssm_role_attach" {
  role       = data.terraform_remote_state.state_000base.outputs.ssm_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

## ----------------------------------
## Key Pair

module "key_pair" {
  source = "github.com/CURRTIS1/AWS-Onboarding/Terraform/modules/key_pair"

  key_name = var.key_name

}

## ----------------------------------
## Autoscaling Group

module "ec2_asg" {
  source = "github.com/CURRTIS1/AWS-Onboarding/Terraform/modules/ec2_asg"

  instance_type        = var.asg_instance_type
  key_pair             = module.key_pair.keypair_id
  security_groups      = [data.terraform_remote_state.state_100security.outputs.sg_ecs]
  iam_instance_profile = data.terraform_remote_state.state_000base.outputs.ssm_profile
  asg_lt_name          = "Curtis-LT-Test"
  asg_name             = "Curtis-ASG-Test2"
  autoscale_min        = 2
  autoscale_max        = 2
  #target_group_arn        = [module.ec2_alb.elb_target_group]
  vpc_subnets             = data.terraform_remote_state.state_000base.outputs.subnet_private
  pre_user_data_commands  = var.pre_user_data_commands
  post_user_data_commands = var.post_user_data_commands
  ami_id                  = var.ami_id
}

## ----------------------------------
## ECR Repository

resource "aws_ecr_repository" "my_ecr_repo" {
  name = "curtis-ecr-repo"
  image_scanning_configuration {
    scan_on_push = true
  }
}


## ----------------------------------
## Codebuild IAM role

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "codebuild.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}


## ----------------------------------
## Codebuild policy

resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild_policy"
  description = "my codebuild policy"
  policy      = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Sid" : "CloudWatchLogsPolicy",
      "Effect" : "Allow",
      "Action" : [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource" : [
        "*"
      ]
    },
    {
      "Sid" : "CodeCommitPolicy",
      "Effect" : "Allow",
      "Action" : [
        "codecommit:GitPull"
      ],
      "Resource" : [
        "*"
      ]
    },
    {
      "Sid" : "S3GetObjectPolicy",
      "Effect" : "Allow",
      "Action" : [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource" : [
        "*"
      ]
    },
    {
      "Sid" : "S3PutObjectPolicy",
      "Effect" : "Allow",
      "Action" : [
        "s3:PutObject"
      ],
      "Resource" : [
        "*"
      ]
    },
    {
      "Sid" : "ECRPullPolicy",
      "Effect" : "Allow",
      "Action" : [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource" : [
        "*"
      ]
    },
    {
      "Sid" : "ECRAuthPolicy",
      "Effect" : "Allow",
      "Action" : [
        "ecr:GetAuthorizationToken"
      ],
      "Resource" : [
        "*"
      ]
    },
    {
      "Sid" : "S3BucketIdentity",
      "Effect" : "Allow",
      "Action" : [
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:CreateNetworkInterfacePermission",
        "ec2:*",
        "ecr:*"
      ],
      "Resource" : [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codebuildrole_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

resource "aws_iam_role_policy_attachment" "codebuildrole_attach2" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

## ----------------------------------
## Codebuild project

resource "aws_codebuild_project" "mycodebuildproject" {
  name         = "my-codebuild-project"
  description  = "Test codebuild project"
  service_role = aws_iam_role.codebuild_role.arn
  source {
    type     = "GITHUB"
    location = "https://github.com/CURRTIS1/Interviewapp.git"
  }
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:1.0"
    privileged_mode = true
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.my_ecr_repo.id
    }
  }
  vpc_config {
    vpc_id             = data.terraform_remote_state.state_000base.outputs.vpc_id
    subnets            = data.terraform_remote_state.state_000base.outputs.subnet_private
    security_group_ids = [data.terraform_remote_state.state_100security.outputs.sg_ecs]
  }
}


## ----------------------------------
## ECS Cluster

resource "aws_ecs_cluster" "Curtis-ECS-Cluster" {
  name = "My-ECS-Cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}


## ----------------------------------
## ECS IAM role

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {
                "Service": [
                  "ecs.amazonaws.com",
                  "ecs-tasks.amazonaws.com"
                ]
              },
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecsrole_attach" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}

## ----------------------------------
## ECS policy

resource "aws_iam_policy" "ecs_policy" {
  name        = "ecs_policy"
  description = "my ecs policy"
  policy      = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Sid" : "ECR",
      "Effect" : "Allow",
      "Action" : [
        "ecr:*"
      ],
      "Resource" : [
        "*"
      ]
    }
  ]
}
EOF
}


## ----------------------------------
## ECS Task definition

resource "aws_ecs_task_definition" "mytaskdef" {
  family                   = "Curtis"
  requires_compatibilities = ["EC2"]
  memory                   = 512
  cpu                      = 256
  network_mode             = "bridge"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.my_ecr_repo.name}:latest"
      cpu       = 1
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          #hostPort      = 80
        }
      ]
    }
  ])
}


## ----------------------------------
## ECS Loadbalancer

module "ec2_alb" {
  source = "github.com/CURRTIS1/AWS-Onboarding/Terraform/modules/ec2_alb"

  vpc_id             = data.terraform_remote_state.state_000base.outputs.vpc_id
  elb_subnets        = data.terraform_remote_state.state_000base.outputs.subnet_public
  elb_securitygroups = [data.terraform_remote_state.state_100security.outputs.sg_alb]
  tg_name            = var.tg_name
  elb_name           = var.elb_name
  elb_port           = 80
  target_type        = var.target_type
  tg_port            = var.tg_port
}


## ----------------------------------
## ECS Service

resource "aws_ecs_service" "myecssvc" {
  name            = "Curtis-ECS-Service"
  cluster         = aws_ecs_cluster.Curtis-ECS-Cluster.id
  task_definition = aws_ecs_task_definition.mytaskdef.id
  desired_count   = 2
  launch_type     = "EC2"
  load_balancer {
    target_group_arn = module.ec2_alb.elb_target_group
    container_name   = "first"
    container_port   = 80
  }
  depends_on = [
    module.ec2_alb.elb
  ]
  placement_constraints {
    type = "distinctInstance"
  }
}


## ----------------------------------
## ALB monitoring

resource "aws_route53_health_check" "alb_check" {
  fqdn              = module.ec2_alb.elb_dns
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
  regions           = ["eu-west-1", "us-east-1", "us-west-1"]
}

resource "aws_sns_topic" "alb_topic" {
  name = "My-alb-check"
}

resource "aws_sns_topic_subscription" "my_alb_sub" {
  topic_arn = aws_sns_topic.alb_topic.arn
  protocol  = "sms"
  endpoint  = "+447801455201"
}

resource "aws_cloudwatch_metric_alarm" "alb_check" {
  alarm_name          = "alb_check"
  metric_name         = "HealthCheckPercentageHealthy"
  statistic           = "Average"
  period              = "300"
  threshold           = "60"
  evaluation_periods  = "2"
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/Route53"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.alb_topic.id]
  ok_actions          = [aws_sns_topic.alb_topic.id]
  dimensions = {
    HealthCheckId = aws_route53_health_check.alb_check.id
  }
}

## ----------------------------------
## CodeCommit repo

resource "aws_codecommit_repository" "Curtis-ecr-Repo" {
  repository_name = "Curtis-ecr-Repo"
  description     = "This is the Repository for my image"
}

resource "aws_s3_bucket" "codebuild_bucket" {
  versioning {
    enabled = true
  }
}


## ----------------------------------
## S3 bucket

resource "null_resource" "my_resource" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "aws s3 sync ${path.module}/app s3://${aws_s3_bucket.codebuild_bucket.id}"
    environment = {
      AWS_ACCESS_KEY_ID     = var.aws_access_key
      AWS_SECRET_ACCESS_KEY = var.aws_secret_key
    }
  }
}


## ----------------------------------
## Codepipeline

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codepipeline_policy" {
  name = "codepipeline_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codebuild_bucket.arn}",
        "${aws_s3_bucket.codebuild_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline_role_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_codepipeline" "mycodepipeline" {
  name     = "Curtis-Codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.codebuild_bucket.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket             = "${aws_s3_bucket.codebuild_bucket.id}"
        S3ObjectKey          = "CWApp.zip"
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.mycodebuildproject.arn}"
      }
    }
  }
}


#################################################################
#######################    PROMETHEUS    ########################
#################################################################


## ----------------------------------
## ECS Service Security Group

resource "aws_security_group" "sg_ECSS" {
  name        = "ECS Service Security Group"
  description = "ECS Service Security Group"
  vpc_id      = data.terraform_remote_state.state_000base.outputs.vpc_id
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
  vpc_id      = data.terraform_remote_state.state_000base.outputs.vpc_id
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
  vpc         = data.terraform_remote_state.state_000base.outputs.vpc_id
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
  subnet_id       = data.terraform_remote_state.state_000base.outputs.subnet_public.0
  security_groups = [aws_security_group.sg_EFS.id]
}

## ----------------------------------
## Prometheus EFS Mount Target 2

resource "aws_efs_mount_target" "efsmount2" {
  file_system_id  = aws_efs_file_system.prometheus_efs.id
  subnet_id       = data.terraform_remote_state.state_000base.outputs.subnet_public.1
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
  vpc_id      = data.terraform_remote_state.state_000base.outputs.vpc_id
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
    subnets          = element([data.terraform_remote_state.state_000base.outputs.subnet_public], 1)
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
    subnets          = element([data.terraform_remote_state.state_000base.outputs.subnet_public], 2)
    security_groups  = [aws_security_group.sg_ECSS.id]
    assign_public_ip = true
  }
}

/**

## ----------------------------------
## ECS Prometheus discovery Task definition

resource "aws_ecs_task_definition" "myprometheustaskdef2" {
  family                   = "prometheus-for-ecs"
  memory                   = 512
  cpu                      = 256
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2", "FARGATE"]
  execution_role_arn       = aws_iam_role.prometheus-execution-role.arn
  task_role_arn            = aws_iam_role.prometheus-role.arn
  volume {
    name = "config"
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
          SourceVolume  = "config"
          ContainerPath = "/output"
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
          SourceVolume  = "config"
          ContainerPath = "/output"
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

*/

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
    subnets          = element([data.terraform_remote_state.state_000base.outputs.subnet_public], 1)
    security_groups  = [aws_security_group.sg_ECSP.id]
    assign_public_ip = true
  }
}

## ----------------------------------
## Grafana Security Group

resource "aws_security_group" "sg_Grafana" {
  name        = "Grafana Security Group"
  description = "Grafana Security Group"
  vpc_id      = data.terraform_remote_state.state_000base.outputs.vpc_id
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
    subnets          = element([data.terraform_remote_state.state_000base.outputs.subnet_public], 1)
    security_groups  = [aws_security_group.sg_Grafana.id]
    assign_public_ip = true
  }
}



#################################################################
########################    TESTING    ##########################
#################################################################

module "ec2_alb_internal" {
  source = "github.com/CURRTIS1/AWS-Onboarding/Terraform/modules/ec2_alb"

  vpc_id             = data.terraform_remote_state.state_000base.outputs.vpc_id
  elb_subnets        = data.terraform_remote_state.state_000base.outputs.subnet_private
  elb_securitygroups = [data.terraform_remote_state.state_100security.outputs.sg_alb]
  elb_internal       = true
  tg_name            = "internal-tg"
  elb_name           = "alb-internal"
  elb_port           = 80
  target_type        = "instance"
  tg_port            = 80
}

## ----------------------------------
## ECS Service

resource "aws_ecs_service" "myecssvc-internal" {
  name            = "Curtis-ECS-Service-Internal"
  cluster         = aws_ecs_cluster.Curtis-ECS-Cluster.id
  task_definition = aws_ecs_task_definition.mytaskdef.id
  desired_count   = 2
  launch_type     = "EC2"
  load_balancer {
    target_group_arn = module.ec2_alb_internal.elb_target_group
    container_name   = "first"
    container_port   = 80
  }
  depends_on = [
    module.ec2_alb_internal.elb
  ]
  placement_constraints {
    type = "distinctInstance"
  }
}

## ----------------------------------
## NLB Target group

resource "aws_lb_target_group" "nlb-tg" {
  name        = "nlb-tg"
  port        = 80
  protocol    = "TCP"
  target_type = "alb"
  vpc_id      = data.terraform_remote_state.state_000base.outputs.vpc_id
}


## ----------------------------------
## NLB 

resource "aws_lb" "networkloadbalancer" {
  name               = "nlb-api-internal"
  internal           = true
  load_balancer_type = "network"
  subnets            = data.terraform_remote_state.state_000base.outputs.subnet_private

  enable_deletion_protection = true

  tags = {
    Environment = "test"
  }
}


## ----------------------------------
## NLB Listener

resource "aws_lb_listener" "nlb-listener" {
  load_balancer_arn = aws_lb.networkloadbalancer.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb-tg.arn
  }
}


## ----------------------------------
## NLB TG attachment

resource "aws_lb_target_group_attachment" "nlb_attachment" {
  target_group_arn = aws_lb_target_group.nlb-tg.arn
  target_id        = module.ec2_alb_internal.elb
  port             = module.ec2_alb_internal.elb_alb_listener
}