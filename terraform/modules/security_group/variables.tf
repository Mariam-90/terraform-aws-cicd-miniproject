variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the security group will be created"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your public IP address in CIDR format for SSH access"
}

variable "name" {
  type        = string
  description = "Name prefix for the security group"
  default     = "terraform"
}
