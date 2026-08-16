

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 22.04)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Public subnet ID from the VPC module"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID from the security_group module"
  type        = string
}

variable "key_name" {
  description = "Name of the existing EC2 key pair for SSH access"
  type        = string
}

variable "github_repo_url" {
  description = "Git URL the instance will clone on first boot"
  type        = string
}

variable "project_name" {
  description = "Project name, used in resource naming and tags"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/production)"
  type        = string
  default     = "dev"
}
