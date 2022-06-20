/*

Module - ecr_repository

This module is used to create an ECR Repository


Usage:

module "ecr_repo" {
  source = "github.com/CURRTIS1/Terraform/modules/ecr_repository"

  repository_name = "my_ecr_repository"
  image_tag_mutability = "MUTABLE"
  image_scanning = false
}


*/

terraform {
  required_version = ">= 1.2.1"
}

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}


## ----------------------------------
## ECR Repository

resource "aws_ecr_repository" "ecr_repository" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.image_scanning
  }
}


## ----------------------------------
## ECR Repository Policy

resource "aws_ecr_repository_policy" "ecr_repository_policy" {
  repository = aws_ecr_repository.ecr_repository.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "AllowDevPull",
            "Effect": "Allow",
            "Principal": {
              "AWS": "arn:aws:iam::249147895833:root"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        },
                {
            "Sid": "AllowIntPull",
            "Effect": "Allow",
            "Principal": {
              "AWS": "arn:aws:iam::249147895833:root"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        },
                {
            "Sid": "AllowStgPull",
            "Effect": "Allow",
            "Principal": {
              "AWS": "arn:aws:iam::249147895833:root"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        }
    ]
}
EOF
}