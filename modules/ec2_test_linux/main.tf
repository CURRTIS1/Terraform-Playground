/*

Module - ec2_test_linux

This module is used to create a test Linux instance


Usage:

module "ec2_test_linux" {
 source = "../../modules/ec2_test_linux"

 linuxtest_instance_name = var.linuxtest_instance_name

}
 
*/


terraform {
  required_version = "~> 1.2.0"
}

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}

data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon", "aws-marketplace"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


## ----------------------------------
## Linux Test Instance

resource "aws_instance" "ec2_linux_test" {
  subnet_id              = var.linuxtest_subnet_id
  vpc_security_group_ids = var.linuxtest_vpc_security_group_ids
  iam_instance_profile   = var.linuxtest_iam_instance_profile
  instance_type          = var.linuxtest_instance_type
  ami                    = data.aws_ami.linux.id
  key_name               = var.linuxtest_key_name

  tags = merge(
    local.tags,
    {
      Name = var.linuxtest_instance_name
    }
  )
}