variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "project_name" {
  type        = string
  description = "Name of the VPC"
  default     = "terraform"
}

variable "cidr_public_subnet" {
  type        = string
  description = "The CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "AZ for the public subnet"
  type        = string
  default     = "us-east-1a"
}


variable "environment" {
  description = "Deployment environment (dev/staging/production)"
  type        = string
  default     = "dev"
}
