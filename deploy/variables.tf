variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-075449515af5df0d1"
}

variable "key_pair_name" {
  description = "Name of existing SSH key pair"
  type        = string
  default     = "etch@stakpak.dev"
}

variable "security_group_name" {
  description = "Name for the security group"
  type        = string
  default     = "autumn-security-group"
}
