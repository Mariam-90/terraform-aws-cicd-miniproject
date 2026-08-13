module "vpc" {
  source             = "./modules/vpc"
  name               = var.name
  vpc_cidr           = var.vpc_cidr
  cidr_public_subnet = var.cidr_public_subnet
}

module "security_group" {
  source = "./modules/security_group"

  name       = var.name
  vpc_id     = module.vpc.vpc_id
  my_ip_cidr = var.my_ip_cidr
}
