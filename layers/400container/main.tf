/*

400container - main.tf

Required layers:
000base
100security

Required modules:

*/

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
## ECS policy attachment

resource "aws_iam_role_policy_attachment" "ecs_ssm_role_attach" {
  role       = data.terraform_remote_state.state_000base.outputs.ssm_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

/*
## ----------------------------------
## Key Pair

module "key_pair" {
  source = "../../modules/key_pair"

  key_name = var.key_name
  public_key = ""
}
*/

## ----------------------------------
## Autoscaling Group

module "ec2_asg" {
  source = "../../modules/ec2_asg"

  instance_type = var.asg_instance_type
  #key_pair             = module.key_pair.keypair_id
  security_groups         = [data.terraform_remote_state.state_100security.outputs.sg_ecs]
  iam_instance_profile    = data.terraform_remote_state.state_000base.outputs.ssm_profile
  asg_lt_name             = "LT-Test"
  asg_name                = "ASG-Test-ECS"
  autoscale_min           = 2
  autoscale_max           = 2
  vpc_subnets             = data.terraform_remote_state.state_000base.outputs.subnet_private
  pre_user_data_commands  = var.pre_user_data_commands
  post_user_data_commands = var.post_user_data_commands
  ami_id                  = var.ami_id
}

## ----------------------------------
## ECR Repository

resource "aws_ecr_repository" "my_ecr_repo" {
  name = "ecr-repo"
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

data "template_file" "buildspec" {
  template = file("${path.module}/app/buildspec.yml")
}

resource "aws_codebuild_project" "mycodebuildproject" {
  name         = "my-codebuild-project"
  description  = "Test codebuild project"
  service_role = aws_iam_role.codebuild_role.arn
  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec.rendered
  }
  artifacts {
    type = "CODEPIPELINE"
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

resource "aws_ecs_cluster" "ECS-Cluster" {
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
      "Action": [
        "ecr:*",
        "logs:*"
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
  family                   = "Family"
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
        }
      ]
    }
  ])
}


## ----------------------------------
## ECS Loadbalancer

module "ec2_alb" {
  source = "../../modules/ec2_alb"

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
  name            = "ECS-Service"
  cluster         = aws_ecs_cluster.ECS-Cluster.id
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
/*
resource "aws_sns_topic_subscription" "my_alb_sub" {
  topic_arn = aws_sns_topic.alb_topic.arn
  protocol  = "sms"
  endpoint  = "+447123456789"
}
*/
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

resource "aws_codecommit_repository" "ecr-Repo" {
  repository_name = "My-ecr-Repo"
  description     = "This is the Repository for my image"
}

resource "aws_s3_bucket" "codebuild_bucket" {
}

resource "aws_s3_bucket_versioning" "codebuild_bucket_versioning" {
  bucket = aws_s3_bucket.codebuild_bucket.id
  versioning_configuration {
    status = "Enabled"
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
## Codepipeline IAM

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


## ----------------------------------
## Codepipeline

resource "aws_codepipeline" "mycodepipeline" {
  name     = "Codepipeline"
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
        S3ObjectKey          = "App.zip"
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


## ----------------------------------
## Internal ALB

module "ec2_alb_internal" {
  source = "../../modules/ec2_alb"

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
  name            = "ECS-Service-Internal"
  cluster         = aws_ecs_cluster.ECS-Cluster.id
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