
terraform {
  required_version = "~> 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "286206761753-klwedolikzimdtoonagjfo"
    key    = "state_490kubernetes"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}
