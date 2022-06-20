/*

Module - eks_cluster

This module is used to create an EKS Cluster


Usage:

module "vpc" {
    source = "github.com/CURRTIS1/AWS-Onboarding/Terraform/modules/eks_cluster"

    ****UPDATE**** = var.****UPDATE****
}


*/

terraform {
  required_version = "1.2.1"
}

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}

/**
## ----------------------------------
## EKS IAM role

resource "eks_iam_role" "eks_role" {
    name = "eks_role"
    
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "eks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

*/