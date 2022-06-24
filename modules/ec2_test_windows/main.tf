/*

Module - ec2_test_windows

This module is used to create a test Windows instance


Usage:

module "ec2_test_windows" {
    source = "../../modules/ec2_test_windows"

    windowstest_instance_name = var.windowstest_instance_name

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

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}


## ----------------------------------
## Windows Test Instance

resource "aws_instance" "ec2_windows_test" {
  subnet_id              = var.windowstest_subnet_id
  vpc_security_group_ids = var.windowstest_vpc_security_group_ids
  iam_instance_profile   = var.windowstest_iam_instance_profile
  instance_type          = var.windowstest_instance_type
  ami                    = data.aws_ami.windows.id
  key_name               = var.windowstest_key_name

  tags = merge(
    local.tags,
    {
      Name = var.windowstest_instance_name
    }
  )
}