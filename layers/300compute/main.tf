/*

300compute - main.tf

Required layers:
000base
100security

Required modules:
key_pair
ec2_alb
ec2_asg
ec2_test_windows
ec2_test_linux

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
    path = "./terraform.300compute.tfstate"
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

data "terraform_remote_state" "state_200data" {
  backend = "local"
  config = {
    path = "${path.module}/../200data/terraform.200data.tfstate"
  }
}


## ----------------------------------
## Key Pair

module "key_pair" {
  source = "../../modules/key_pair"

  key_name = var.key_name
 # public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxEjd30DO25FSHbpUEzmcGetk/vSP7u0TRkuISLhOudze5ULm6vyV6F+Tv4lNezINnc2U9JhDBU+wlxLXsbN1mefPVVl9w5suVARDz54z20T2IoXulme04RjteqeKkMw2/L5iSbc+uTJj59C57D/BJqxd54P+yLAbYB5QCcnACaCqHYEAJjWv5hQS5XE0WNmRzVkohsD7IoanmF23RRwXsS5tuoqObcjDUOruUj4/t/6lLXA6TwNE+f/XWD4mxBK0Ec1YX7IVGDfhvBHJ+03nY6xiQkLEqNyzLlGT9Y1S+9W/6z8O0TlzH79z3FuoPUTPlhUtdTYtt81RUTTxpKrDN curtis@CURTIS-mac"

}


## ----------------------------------
## Application Loadbalancer

module "ec2_alb" {
  source = "../../modules/ec2_alb"

  vpc_id             = data.terraform_remote_state.state_000base.outputs.vpc_id
  elb_subnets        = data.terraform_remote_state.state_000base.outputs.subnet_public
  elb_securitygroups = [data.terraform_remote_state.state_100security.outputs.sg_alb]
  tg_name            = var.tg_name
  elb_name           = var.elb_name
}


## ----------------------------------
## Autoscaling Group

module "ec2_asg" {
  source = "../../modules/ec2_asg"

  instance_type           = var.asg_instance_type
  key_pair                = module.key_pair.keypair_id
  security_groups         = [data.terraform_remote_state.state_100security.outputs.sg_web]
  iam_instance_profile    = data.terraform_remote_state.state_000base.outputs.ssm_profile
  asg_lt_name             = "LT-Test"
  asg_name                = "ASG-Test"
  autoscale_min           = 1
  autoscale_max           = 1
  target_group_arn        = [module.ec2_alb.elb_target_group]
  vpc_subnets             = data.terraform_remote_state.state_000base.outputs.subnet_private
  pre_user_data_commands  = var.pre_user_data_commands
  post_user_data_commands = var.post_user_data_commands
}


## ----------------------------------
## Windows test instance

module "ec2_test_windows" {
  source = "../../modules/ec2_test_windows"

  windowstest_instance_name          = var.windowstest_instance_name
  windowstest_subnet_id              = data.terraform_remote_state.state_000base.outputs.subnet_private[0]
  windowstest_vpc_security_group_ids = [data.terraform_remote_state.state_100security.outputs.sg_testing]
  windowstest_iam_instance_profile   = data.terraform_remote_state.state_000base.outputs.ssm_profile
  windowstest_instance_type          = var.windowstest_instance_type
  windowstest_key_name               = module.key_pair.keypair_id
}


## ----------------------------------
## Linux test instance

module "ec2_test_linux" {
  source = "../../modules/ec2_test_linux"

  linuxtest_instance_name          = var.linuxtest_instance_name
  linuxtest_subnet_id              = data.terraform_remote_state.state_000base.outputs.subnet_private[0]
  linuxtest_vpc_security_group_ids = [data.terraform_remote_state.state_100security.outputs.sg_testing]
  linuxtest_iam_instance_profile   = data.terraform_remote_state.state_000base.outputs.ssm_profile
  linuxtest_instance_type          = var.linuxtest_instance_type
  linuxtest_key_name               = module.key_pair.keypair_id
}