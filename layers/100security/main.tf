/*

100security - main.tf

Required layers:
000base

Required modules:
security_groups

*/

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}

## ----------------------------------
## sg module

module "security_groups" {
  source = "../../modules/security_groups"

  vpc_id = data.terraform_remote_state.state_000base.outputs.vpc_id
}