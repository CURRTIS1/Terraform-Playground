/*

410codedeploy - main.tf

Required layers:
000base
100security

Required modules:


*/

terraform {
  required_version = "~> 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "local" {
    path = "./terraform.410codedeploy.tfstate"
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
  backend = "local"
  config = {
    path = "${path.module}/../000base/terraform.000base.tfstate"
  }
}

data "terraform_remote_state" "state_100security" {
  backend = "local"
  config = {
    path = "${path.module}/../100security/terraform.100security.tfstate"
  }
}

data "aws_caller_identity" "current" {
}


data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon", "aws-marketplace"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


## ----------------------------------
## CodeDeploy S3 bucket

resource "aws_s3_bucket" "codedeploy_bucket" {
}

resource "aws_s3_bucket_versioning" "codedeploy_bucket_versioning" {
  bucket = aws_s3_bucket.codedeploy_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


## ----------------------------------
## SSM IAM role

resource "aws_iam_role" "ssm_role" {
  name               = "ec2-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssmrole_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssmrole_attach2" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ssm_role.name
}


## ----------------------------------
## Application Loadbalancer

module "ec2_alb" {
  source = "../../modules/ec2_alb"

  vpc_id             = data.terraform_remote_state.state_000base.outputs.vpc_id
  elb_subnets        = data.terraform_remote_state.state_000base.outputs.subnet_public
  elb_securitygroups = [data.terraform_remote_state.state_100security.outputs.sg_alb]
  tg_name            = "CodeDeploy-TG"
  elb_name           = "CodeDeploy-ELB"
}


## ----------------------------------
## ASG Launch Template

resource "aws_launch_template" "mylaunchtemplate" {
  image_id               = data.aws_ami.linux.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [data.terraform_remote_state.state_100security.outputs.sg_web]
  user_data              = base64encode(templatefile("${path.module}/user_data_script.sh", { region = var.region }))
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  tags = merge(
    local.tags, {
      "Name" = "CodeDeploy-LT"
    }
  )
}


## ----------------------------------
## ASG

resource "aws_autoscaling_group" "myasg" {
  name                = "MyCodeDeployASG"
  max_size            = 2
  min_size            = 1
  target_group_arns   = [module.ec2_alb.elb_target_group]
  vpc_zone_identifier = data.terraform_remote_state.state_000base.outputs.subnet_private
  health_check_type   = "EC2"
  launch_template {
    name    = aws_launch_template.mylaunchtemplate.name
    version = "$Latest"
  }

  tag {
    key                 = "environment"
    value               = var.environment
    propagate_at_launch = true
  }
  tag {
    key                 = "layer"
    value               = var.layer
    propagate_at_launch = true
  }
  tag {
    key                 = "terraform"
    value               = "true"
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = "EC2-Linux"
    propagate_at_launch = true
  }
  tag {
    key                 = "Codedeploy"
    value               = "Yes"
    propagate_at_launch = true
  }
}


## ----------------------------------
## Codedeploy app

resource "aws_codedeploy_app" "codedeploy_app" {
  compute_platform = "Server"
  name             = "MyCodeDeployApp"
  tags             = local.tags
}


## ----------------------------------
## Codedeploy IAM Role

resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


## ----------------------------------
## Codedeploy IAM Policy

resource "aws_iam_policy" "codedeploy_policy" {
  name = "codedeploy_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "iam:PassRole",
        "ec2:CreateTags",
        "ec2:RunInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

## ----------------------------------
## Codedeploy IAM Policy attachments

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_role.name
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployattachment" {
  policy_arn = aws_iam_policy.codedeploy_policy.arn
  role       = aws_iam_role.codedeploy_role.name
}


## ----------------------------------
## Codedeploy deploy push

resource "null_resource" "my_codedeploy_resource" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/webapp"
    command     = "aws deploy push --application-name ${aws_codedeploy_app.codedeploy_app.name} --s3-location s3://${aws_s3_bucket.codedeploy_bucket.id}/webapp.zip --ignore-hidden-files"
    environment = {
      AWS_ACCESS_KEY_ID     = var.aws_access_key
      AWS_SECRET_ACCESS_KEY = var.aws_secret_key
    }
  }
}


## ----------------------------------
## Codedeploy Deployment Group

resource "aws_codedeploy_deployment_group" "aws_codedeploy_dg" {
  app_name               = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name  = "MyCodeDeployDeploymentGroup"
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  autoscaling_groups = [aws_autoscaling_group.myasg.name]

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_info {
      name = module.ec2_alb.elb_target_group_name
    }
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }
}


## ----------------------------------
## Codedeploy deploy push

resource "null_resource" "my_codedeploy_resource_deployment" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command     = "aws deploy create-deployment --application-name ${aws_codedeploy_app.codedeploy_app.name} --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name ${aws_codedeploy_deployment_group.aws_codedeploy_dg.deployment_group_name} --s3-location bucket=${aws_s3_bucket.codedeploy_bucket.id},bundleType=zip,key=webapp.zip --region ${var.region}"
    environment = {
      AWS_ACCESS_KEY_ID     = var.aws_access_key
      AWS_SECRET_ACCESS_KEY = var.aws_secret_key
    }
  }
}