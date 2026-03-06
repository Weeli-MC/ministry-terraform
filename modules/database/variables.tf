variable "workload_vpc_id" {}
variable "internet_vpc_cidr_block" {}
variable "data_subnet_id" {}
variable "app_subnet_id" {}

variable "db_username" {
  description = "The master username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}
