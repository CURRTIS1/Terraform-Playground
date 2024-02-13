
terraform {
  required_version = "~> 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "808914136833-qgltmpqbbwwtkvgzfbisho"
    key    = "000base"
    region = "us-east-1"
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA3YVYKF4AVII2M7HV"
  secret_key = "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"
}
