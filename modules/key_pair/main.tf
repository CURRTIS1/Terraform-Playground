/*

Module - key_pair

This module is used to create a mySQL RDS instancs


Usage:

module "key_pair" {
    source = "github.com/CURRTIS1/AWS-Onboarding/Terraform/modules/key_pair"

    key_name = var.key_name

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
## EC2 Key Pair

resource "aws_key_pair" "mykp" {
  key_name   = var.key_name
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxEjd30DO25FSHbpUEzmcGetk/vSP7u0TRkuISLhOudze5ULm6vyV6F+Tv4lNezINnc2U9JhDBU+wlxLXsbN1mefPVVl9w5suVARDz54z20T2IoXulme04RjteqeKkMw2/L5iSbc+uTJj59C57D/BJqxd54P+yLAbYB5QCcnACaCqHYEAJjWv5hQS5XE0WNmRzVkohsD7IoanmF23RRwXsS5tuoqObcjDUOruUj4/t/6lLXA6TwNE+f/XWD4mxBK0Ec1YX7IVGDfhvBHJ+03nY6xiQkLEqNyzLlGT9Y1S+9W/6z8O0TlzH79z3FuoPUTPlhUtdTYtt81RUTTxpKrDN curtis@CURTIS-mac"

  tags = merge(
    local.tags, {
      "Name" = var.key_name
    }
  )
}