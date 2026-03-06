terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

module "networking" {
  source = "./modules/networking"
}

module "compute" {
  source          = "./modules/compute"
  internet_vpc_id = module.networking.internet_vpc_id
  subnet_ids      = [module.networking.gateway_subnet_id, module.networking.firewall_subnet_id]
}

module "database" {
  source                  = "./modules/database"
  workload_vpc_id         = module.networking.workload_vpc_id
  internet_vpc_cidr_block = module.networking.internet_vpc_cidr_block
  data_subnet_id          = module.networking.data_subnet_id
  app_subnet_id           = module.networking.app_subnet_id
  db_username             = var.db_username
  db_password             = var.db_password
}
