/*
 
Module - ssm_role

This module is used to create an SSM role for EC2 instances

Usage:

module "ssm_role" {
    source = "github.com/CURRTIS1/Terraform/modules/ssm_role"

    ssm_role_name = "ssm_role"

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


## ----------------------------------
## SSM IAM role

resource "aws_iam_role" "ssm_role" {
  name = var.ssm_role_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssmrole_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = var.ssm_profile_name
  role = aws_iam_role.ssm_role.name
}