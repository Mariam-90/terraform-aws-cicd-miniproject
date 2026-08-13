
output "vpc_id"{
    value       = aws_vpc.this.id
    description = "The ID of the VPC"
}

output "public_subnet_id"{
    value = aws_subnet.public_subnet.id
    
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.gw.id 
  description = "The ID of the internet gateway"
}