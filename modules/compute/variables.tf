variable "internet_vpc_id" {}

variable "internet_vpc_cidr" {}

variable "subnet_ids" {
  type = list(string)
}

variable "workload_vpc_id" {}

variable "app_subnet_id" {}
