/*

200data - main.tf

Required layers:
000base
100security

Required modules:
rds_mysql

*/

terraform {
  required_version = "~> 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "./terraform.200data.tfstate"
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


## ----------------------------------
## RDS Instances

module "rds_mysql" {
  source = "../../modules/rds_mysql"

  subnet_ids             = data.terraform_remote_state.state_000base.outputs.subnet_private
  engine_version         = var.engine_version
  password               = var.password
  vpc_security_group_ids = [data.terraform_remote_state.state_100security.outputs.sg_rds]

}