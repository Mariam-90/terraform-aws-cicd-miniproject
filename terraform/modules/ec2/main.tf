resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    github_repo_url = var.github_repo_url
  })

  tags = {
    Name        = "${var.project_name}-app"
    Environment = var.environment
    Project     = var.project_name
  }
}
