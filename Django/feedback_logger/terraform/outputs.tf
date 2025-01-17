output "instance_public_key" {
  description = "Public key of oe-key-pair"
  value       = tls_private_key.oei-key.public_key_openssh
  sensitive   = true
}

output "instance_private_key" {
  description = "Private key of oe-key-pair"
  value       = tls_private_key.oei-key.private_key_pem
  sensitive   = true
}

output "instance_profile_name" {
  value       = aws_iam_instance_profile.ssm_instance_profile.name
  description = "Instance profile name for EC2 instances to use with Systems Manager."
}
