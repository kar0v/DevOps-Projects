variable "db_username" {
  description = "The username for the database"
  type        = string
  default     = "psql_admin"
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  default     = "psql_securepassword"
}

variable "allowed_ips" {
  description = "The allowed IPs for the bastion security group"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
