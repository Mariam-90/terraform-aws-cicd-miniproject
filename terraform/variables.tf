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

variable "project_name" {
  type        = string
  description = "Name of the VPC"
  default     = "terraform-vpc"
}

variable "cidr_public_subnet" {
  type        = string
  description = "The CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}
variable "my_ip_cidr" {
  type        = string
  description = "My public IP address for SSH access"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instance (Ubuntu 22.04, region-specific — look this up, don't hardcode from a tutorial)"
}

variable "key_name" {
  type        = string
  description = "Name of your existing EC2 key pair for SSH access"
}

variable "github_repo_url" {
  type        = string
  description = "Git URL the instance clones on first boot"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}
