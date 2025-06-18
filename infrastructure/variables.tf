### PostgreSQL
variable "db_username" {
  type    = string
  default = "seemianki"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "allowed_ips" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

### remote-state backend (override in CLI or tfvars)
variable "backend_rg_name" {
  type    = string
  default = "tfstate-rg"
}

variable "backend_sa_name" {
  type    = string
  default = "tfstatestorage"
}

variable "backend_container_name" {
  type    = string
  default = "tfstate"
}
