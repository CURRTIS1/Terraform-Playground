/*

200data - main.tf

Required layers:
000base
100security

Required modules:
rds_mysql

*/

terraform {
  required_version = "1.2.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket  = "curtis-terraform-test-2020"
    key     = "terraform.200data.tfstate"
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


## ----------------------------------
## RDS Instances

module "rds_mysql" {
  source = "github.com/CURRTIS1/AWS-Onboarding/Terraform/modules/rds_mysql"

  subnet_ids             = data.terraform_remote_state.state_000base.outputs.subnet_private
  engine_version         = var.engine_version
  password               = var.password
  vpc_security_group_ids = [data.terraform_remote_state.state_100security.outputs.sg_rds]

}