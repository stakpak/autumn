terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "autumn-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = var.region
}

# Data source for existing Route53 zone
data "aws_route53_zone" "stakpak_dev" {
  name         = "stakpak.dev."
  private_zone = false
}

# Use existing key pair
data "aws_key_pair" "existing" {
  key_name = var.key_pair_name
}

# Use existing prod VPC
data "aws_vpc" "prod" {
  filter {
    name   = "tag:Name"
    values = ["prod"]
  }
}

# Use existing prod public subnet
data "aws_subnet" "prod_public" {
  filter {
    name   = "tag:Name"
    values = ["prod-public-eu-north-1a"]
  }
  vpc_id = data.aws_vpc.prod.id
}

# Security Group
resource "aws_security_group" "autumn" {
  name        = var.security_group_name
  description = "Security group for autumn application"
  vpc_id      = data.aws_vpc.prod.id

  tags = {
    Name = var.security_group_name
  }
}

# Security Group Rules
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.autumn.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "SSH access"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.autumn.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "HTTP access"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.autumn.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  description       = "HTTPS access"
}

resource "aws_vpc_security_group_egress_rule" "all_traffic" {
  security_group_id = aws_security_group.autumn.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

# Note: Using existing key pair specified in variables

# User data script - loaded from external file
locals {
  user_data      = file("${path.module}/user-data.sh")
  user_data_hash = filemd5("${path.module}/user-data.sh")
}

# EC2 Instance
resource "aws_instance" "autumn" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.existing.key_name
  subnet_id              = data.aws_subnet.prod_public.id
  vpc_security_group_ids = [aws_security_group.autumn.id]

  user_data                   = local.user_data
  # user_data_replace_on_change = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "autumn-server"
  }
}

# Elastic IP for stable IP address
resource "aws_eip" "autumn" {
  instance = aws_instance.autumn.id
  domain   = "vpc"

  tags = {
    Name = "autumn-eip"
  }
}

# Route53 Records (using Elastic IP)
resource "aws_route53_record" "finance" {
  zone_id = data.aws_route53_zone.stakpak_dev.zone_id
  name    = "finance.stakpak.dev"
  type    = "A"
  ttl     = 300
  records = [aws_eip.autumn.public_ip]
}

resource "aws_route53_record" "api_finance" {
  zone_id = data.aws_route53_zone.stakpak_dev.zone_id
  name    = "api-finance.stakpak.dev"
  type    = "A"
  ttl     = 300
  records = [aws_eip.autumn.public_ip]
}
