output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.autumn.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance (Elastic IP)"
  value       = aws_eip.autumn.public_ip
}

output "elastic_ip_id" {
  description = "ID of the Elastic IP"
  value       = aws_eip.autumn.id
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.autumn.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_eip.autumn.public_ip}"
}

output "finance_url" {
  description = "URL for finance application"
  value       = "https://finance.stakpak.dev"
}

output "api_finance_url" {
  description = "URL for API finance application"
  value       = "https://api-finance.stakpak.dev"
}

output "key_pair_name" {
  description = "Name of the SSH key pair being used"
  value       = var.key_pair_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.prod.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.autumn.id
}
