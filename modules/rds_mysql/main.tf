/*

Module - rds_mysql

This module is used to create a mySQL RDS instance


Usage

module "rds_mysql" {
    source = "../../modules/rds_mysql"

    engine_version = var.engine_version

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
## RDS Subnet Group

resource "aws_db_subnet_group" "myrdsgroup" {
  name       = var.subnet_group_name
  subnet_ids = var.subnet_ids

  tags = merge(
    local.tags, {
      "Name" = var.subnet_group_name
    }
  )
}


## ----------------------------------
## RDS Instances

resource "aws_db_instance" "myrdsinstance" {
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  engine                 = "mysql"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.name
  multi_az               = var.multi_az
  identifier             = var.identifier
  port                   = var.port
  db_subnet_group_name   = aws_db_subnet_group.myrdsgroup.id
  username               = var.username
  password               = var.password
  skip_final_snapshot    = var.skip_final_snapshot
  vpc_security_group_ids = var.vpc_security_group_ids

  tags = merge(
    local.tags, {
      "Name" = var.name
    }
  )
}