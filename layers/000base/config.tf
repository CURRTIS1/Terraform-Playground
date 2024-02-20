
terraform {
  required_version = "~> 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "325618140111-bcamjausyncneqseyuwrhd"
    key    = "state_000base"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}