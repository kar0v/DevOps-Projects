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
