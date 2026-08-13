variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "name" {
  type        = string
  description = "Name of the VPC"
  default     = "terraform-vpc"
}

variable "cidr_public_subnet" {
  type        = string
  description = "The CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}