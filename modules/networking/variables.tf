variable "internet_vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "workload_vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "firewall_subnet_cidr" {
  default = "10.0.10.0/24"
}

variable "gateway_subnet_cidr" {
  default = "10.0.20.0/24"
}

variable "web_subnet_cidr" {
  default = "10.1.10.0/24"
}

variable "app_subnet_cidr" {
  default = "10.1.20.0/24"
}

variable "data_subnet_cidr" {
  default = "10.1.30.0/24"
}

variable "internet_tgw_subnet_cidr" {
  default = "10.0.100.0/24"
}

variable "workload_tgw_subnet_cidr" {
  default = "10.1.100.0/24"
}
