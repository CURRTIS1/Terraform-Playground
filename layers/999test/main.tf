/*

999test - main.tf

Required layers:


Required modules:

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
    key     = "terraform.999test.tfstate"
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

# https://github.com/terraform-aws-modules/terraform-aws-vpc

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "prod-vpc"
  cidr = "172.17.0.0/16"

# CHANGE AZ to eu-west-2
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["172.17.0.0/19", "172.17.64.0/19"]
  public_subnets  = ["172.17.32.0/20", "172.17.96.0/20"]

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true
  enable_vpn_gateway = true


  tags = {
    Terraform = "true"
    Environment = "prod"
  }
}