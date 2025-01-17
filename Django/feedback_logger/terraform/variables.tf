variable "db_username" {
  description = "The username for the database"
  type        = string
  default     = "psql_admin"
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  default     = "psql_securepassword" # The real password is stored in the secrets manager due to the usage of the RDS Module
}

variable "allowed_ips" {
  description = "The allowed IPs for the bastion security group"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

