/*

100security - main.tf

Required layers:
000base

Required modules:
security_groups

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
    path = "./terraform.100security.tfstate"
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


## ----------------------------------
## sg module

module "security_groups" {
  source = "../../modules/security_groups"

  vpc_id = data.terraform_remote_state.state_000base.outputs.vpc_id
}