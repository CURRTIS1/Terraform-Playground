/*

200data - main.tf

Required layers:
000base
100security

Required modules:
rds_mysql

*/

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}

## ----------------------------------
## RDS Instances

module "rds_mysql" {
  source = "../../modules/rds_mysql"

  subnet_ids             = data.terraform_remote_state.state_000base.outputs.subnet_private
  engine_version         = var.engine_version
  password               = var.password
  vpc_security_group_ids = [data.terraform_remote_state.state_100security.outputs.sg_rds]

}