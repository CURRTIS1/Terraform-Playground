/*

Module - ec2_asg

This module is used to create an Autoscaling group with EC2 instances


Usage:

module "ec2_asg" {
    source = "../../modules/ec2_asg"

    image_id = var.ami_id
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

data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon", "aws-marketplace"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

## ----------------------------------
## ASG Launch Template

resource "aws_launch_template" "mylaunchtemplate" {
  image_id               = var.ami_id != "" ? var.ami_id : data.aws_ami.linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair
  vpc_security_group_ids = var.security_groups
  user_data = base64encode(templatefile("${path.module}/user_data_script.sh", {
    pre_user_data_commands  = var.pre_user_data_commands
    post_user_data_commands = var.post_user_data_commands
  }))
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  tags = merge(
    local.tags, {
      "Name" = var.asg_lt_name
    }
  )
}


## ----------------------------------
## ASG

resource "aws_autoscaling_group" "myasg" {
  name                = var.asg_name
  max_size            = var.autoscale_max
  min_size            = var.autoscale_min
  target_group_arns   = var.target_group_arn
  vpc_zone_identifier = var.vpc_subnets
  health_check_type   = var.health_check
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
}