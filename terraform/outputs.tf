
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "subnet_id" {
  value = module.vpc.public_subnet_id

}

output "internet_gateway" {
  value       = module.vpc.internet_gateway_id
  description = "The ID of the internet gateway"
}
output "app_public_ip" {
  value = module.ec2.public_ip
}
