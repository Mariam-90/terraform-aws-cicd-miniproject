module "vpc" {
  source             = "./modules/vpc"
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  cidr_public_subnet = var.cidr_public_subnet
}

module "security_group" {
  source       = "./modules/security_group"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  my_ip_cidr   = var.my_ip_cidr
}

module "ec2" {
  source            = "./modules/ec2"
  project_name      = var.project_name
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_group.security_group_id
  ami_id            = var.ami_id
  key_name          = var.key_name
  github_repo_url   = var.github_repo_url
  environment       = var.environment
}
