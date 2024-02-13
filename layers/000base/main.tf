/*

000base - main.tf

Required modules:
vpc_basenetwork

*/

## ----------------------------------
## vpc module

module "vpc_basenetwork" {
  source = "../../modules/vpc_basenetwork"

  vpc_cidr             = var.vpc_cidr
  subnet_public_range  = var.subnet_public_range
  subnet_private_range = var.subnet_private_range
  vpc_name             = var.vpc_name
}


## ----------------------------------
## ssm role module

module "ssm_role" {
  source = "../../modules/ssm_role"

  ssm_role_name = var.ssm_role_name
}