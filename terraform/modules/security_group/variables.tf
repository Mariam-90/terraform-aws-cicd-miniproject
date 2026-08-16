variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the security group will be created"
}

variable "project_name" {
  type        = string
  description = "Name prefix for the security group"
  default     = "terraform"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your public IP address in CIDR format for SSH access"
  validation {
    condition     = can(cidrhost(var.my_ip_cidr, 0))
    error_message = "my_ip_cidr must be a valid CIDR block, e.g. 1.2.3.4/32."
  }
}
