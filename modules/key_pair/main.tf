/*

Module - key_pair

This module is used to create a mySQL RDS instancs


Usage:

module "key_pair" {
    source = "../../modules/key_pair"

    key_name = var.key_name

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


## ----------------------------------
## EC2 Key Pair

resource "aws_key_pair" "mykp" {
  key_name   = var.key_name
  public_key = var.public_key

  tags = merge(
    local.tags, {
      "Name" = var.key_name
    }
  )
}