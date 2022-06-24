/*

450promgrafana - main.tf

Required layers:
000base

Required modules:
prometheus_grafana

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
    path = "./terraform.450promgrafana.tfstate"
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
## Prometheus  and Grafana

module "prometheus_grafana" {
  source = "../../modules/prometheus_grafana"

  vpc_id         = data.terraform_remote_state.state_000base.outputs.vpc_id
  efs_subnet_id1 = data.terraform_remote_state.state_000base.outputs.subnet_public.0
  efs_subnet_id2 = data.terraform_remote_state.state_000base.outputs.subnet_public.1
  ecs_subnet_id1 = [data.terraform_remote_state.state_000base.outputs.subnet_public.0]
  ecs_subnet_id2 = [data.terraform_remote_state.state_000base.outputs.subnet_public.1]
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
}