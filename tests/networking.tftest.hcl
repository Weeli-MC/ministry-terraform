mock_provider "aws" {}

run "test_vpc_cidrs" {
  command = plan

  module {
    source = "./modules/networking"
  }

  assert {
    condition     = aws_vpc.internet_vpc.cidr_block == "10.0.0.0/16"
    error_message = "Internet VPC CIDR should be 10.0.0.0/16"
  }

  assert {
    condition     = aws_vpc.workload_vpc.cidr_block == "10.1.0.0/16"
    error_message = "Workload VPC CIDR should be 10.1.0.0/16"
  }

  assert {
    condition     = aws_vpc.internet_vpc.enable_dns_hostnames == true
    error_message = "Internet VPC should have DNS hostnames enabled"
  }

  assert {
    condition     = aws_vpc.workload_vpc.enable_dns_hostnames == true
    error_message = "Workload VPC should have DNS hostnames enabled"
  }
}

run "test_subnet_cidrs" {
  command = plan

  module {
    source = "./modules/networking"
  }

  assert {
    condition     = aws_subnet.firewall.cidr_block == "10.0.10.0/24"
    error_message = "Firewall subnet CIDR should be 10.0.10.0/24"
  }

  assert {
    condition     = aws_subnet.gateway.cidr_block == "10.0.20.0/24"
    error_message = "Gateway subnet CIDR should be 10.0.20.0/24"
  }

  assert {
    condition     = aws_subnet.web.cidr_block == "10.1.10.0/24"
    error_message = "Web subnet CIDR should be 10.1.10.0/24"
  }

  assert {
    condition     = aws_subnet.app.cidr_block == "10.1.20.0/24"
    error_message = "App subnet CIDR should be 10.1.20.0/24"
  }

  assert {
    condition     = aws_subnet.data.cidr_block == "10.1.30.0/24"
    error_message = "Data subnet CIDR should be 10.1.30.0/24"
  }

  assert {
    condition     = aws_subnet.internet_tgw_subnet.cidr_block == "10.0.100.0/24"
    error_message = "Internet TGW subnet CIDR should be 10.0.100.0/24"
  }

  assert {
    condition     = aws_subnet.workload_tgw_subnet.cidr_block == "10.1.100.0/24"
    error_message = "Workload TGW subnet CIDR should be 10.1.100.0/24"
  }
}

run "test_subnet_vpc_placement" {
  command = plan

  module {
    source = "./modules/networking"
  }

  # Internet VPC subnets
  assert {
    condition     = aws_subnet.firewall.vpc_id == aws_vpc.internet_vpc.id
    error_message = "Firewall subnet should be in the Internet VPC"
  }

  assert {
    condition     = aws_subnet.gateway.vpc_id == aws_vpc.internet_vpc.id
    error_message = "Gateway subnet should be in the Internet VPC"
  }

  assert {
    condition     = aws_subnet.internet_tgw_subnet.vpc_id == aws_vpc.internet_vpc.id
    error_message = "Internet TGW subnet should be in the Internet VPC"
  }

  # Workload VPC subnets
  assert {
    condition     = aws_subnet.web.vpc_id == aws_vpc.workload_vpc.id
    error_message = "Web subnet should be in the Workload VPC"
  }

  assert {
    condition     = aws_subnet.app.vpc_id == aws_vpc.workload_vpc.id
    error_message = "App subnet should be in the Workload VPC"
  }

  assert {
    condition     = aws_subnet.data.vpc_id == aws_vpc.workload_vpc.id
    error_message = "Data subnet should be in the Workload VPC"
  }

  assert {
    condition     = aws_subnet.workload_tgw_subnet.vpc_id == aws_vpc.workload_vpc.id
    error_message = "Workload TGW subnet should be in the Workload VPC"
  }
}

run "test_internet_gateway" {
  command = plan

  module {
    source = "./modules/networking"
  }

  assert {
    condition     = aws_internet_gateway.igw.vpc_id == aws_vpc.internet_vpc.id
    error_message = "Internet Gateway should be attached to the Internet VPC"
  }

  assert {
    condition     = aws_internet_gateway.igw.tags["Name"] == "Main-IGW"
    error_message = "Internet Gateway should be tagged as Main-IGW"
  }
}

run "test_nat_gateway" {
  command = plan

  module {
    source = "./modules/networking"
  }

  assert {
    condition     = aws_nat_gateway.main_nat.subnet_id == aws_subnet.gateway.id
    error_message = "NAT Gateway should be in the Gateway subnet"
  }

  assert {
    condition     = aws_nat_gateway.main_nat.allocation_id == aws_eip.nat_eip.id
    error_message = "NAT Gateway should use the allocated EIP"
  }

  assert {
    condition     = aws_nat_gateway.main_nat.tags["Name"] == "Main-NAT-Gateway"
    error_message = "NAT Gateway should be tagged as Main-NAT-Gateway"
  }

  assert {
    condition     = aws_eip.nat_eip.domain == "vpc"
    error_message = "EIP for NAT Gateway should be in VPC domain"
  }
}

run "test_transit_gateway" {
  command = plan

  module {
    source = "./modules/networking"
  }

  assert {
    condition     = aws_ec2_transit_gateway.main-tgw.tags["Name"] == "Main-TGW"
    error_message = "Transit Gateway should be tagged as Main-TGW"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.internet_attach.vpc_id == aws_vpc.internet_vpc.id
    error_message = "Internet TGW attachment should be in the Internet VPC"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.workload_attach.vpc_id == aws_vpc.workload_vpc.id
    error_message = "Workload TGW attachment should be in the Workload VPC"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.internet_attach.transit_gateway_id == aws_ec2_transit_gateway.main-tgw.id
    error_message = "Internet TGW attachment should reference the main Transit Gateway"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.workload_attach.transit_gateway_id == aws_ec2_transit_gateway.main-tgw.id
    error_message = "Workload TGW attachment should reference the main Transit Gateway"
  }
}

run "test_route_tables" {
  command = plan

  module {
    source = "./modules/networking"
  }

  assert {
    condition     = aws_route_table.public_rt.vpc_id == aws_vpc.internet_vpc.id
    error_message = "Public route table should be in the Internet VPC"
  }

  assert {
    condition     = aws_route_table.private_rt.vpc_id == aws_vpc.workload_vpc.id
    error_message = "Private route table should be in the Workload VPC"
  }

  assert {
    condition     = one([for r in aws_route_table.public_rt.route : r if r.cidr_block == "0.0.0.0/0"]) != null
    error_message = "Public route table should have a default route (0.0.0.0/0)"
  }

  assert {
    condition     = one([for r in aws_route_table.private_rt.route : r if r.cidr_block == "0.0.0.0/0"]) != null
    error_message = "Private route table should have a default route (0.0.0.0/0) via Transit Gateway"
  }
}

run "test_route_table_associations" {
  command = plan

  module {
    source = "./modules/networking"
  }

  assert {
    condition     = aws_route_table_association.gateway_attach.subnet_id == aws_subnet.gateway.id
    error_message = "Gateway subnet should be associated with the public route table"
  }

  assert {
    condition     = aws_route_table_association.gateway_attach.route_table_id == aws_route_table.public_rt.id
    error_message = "Gateway subnet should be associated with the public route table"
  }

  assert {
    condition     = aws_route_table_association.firewall_association.subnet_id == aws_subnet.firewall.id
    error_message = "Firewall subnet should be associated with the public route table"
  }

  assert {
    condition     = aws_route_table_association.app_private.subnet_id == aws_subnet.app.id
    error_message = "App subnet should be associated with the private route table"
  }

  assert {
    condition     = aws_route_table_association.data_private.subnet_id == aws_subnet.data.id
    error_message = "Data subnet should be associated with the private route table"
  }
}
