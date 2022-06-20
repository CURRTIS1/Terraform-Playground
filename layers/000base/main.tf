/*

000base - main.tf

Required modules:
vpc_basenetwork

*/

terraform {
  required_version = "1.2.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "local" {
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "terraform_remote_state" "local_state" {
  backend = "local"

  config = {
    path = "${path.module}/terraform.000base.tfstate"
  }
}

## ----------------------------------
## vpc module

module "vpc_basenetwork" {
  source = "github.com/CURRTIS1/Terraform/modules/vpc_basenetwork"

  vpc_cidr             = var.vpc_cidr
  subnet_public_range  = var.subnet_public_range
  subnet_private_range = var.subnet_private_range
  vpc_name             = var.vpc_name
}


## ----------------------------------
## ssm role module

module "ssm_role" {
  source = "github.com/CURRTIS1/AWS-Onboarding/Terraform/modules/ssm_role"

  ssm_role_name = var.ssm_role_name
}