mock_provider "aws" {}

variables {
}

run "validate_networking_logic" {
  command = plan

  module {
    source = "./modules/networking"
  }

  assert {
    condition     = aws_vpc.internet_vpc.cidr_block == "10.0.0.0/16" && aws_vpc.workload_vpc.cidr_block == "10.1.0.0/16"
    error_message = "VPC CIDR blocks are incorrect."
  }

  assert {
    condition     = aws_internet_gateway.igw.vpc_id == aws_vpc.internet_vpc.id
    error_message = "IGW is not attached to the correct VPC."
  }

  assert {
    condition = alltrue([
      aws_subnet.firewall.cidr_block == "10.0.10.0/24",
      aws_subnet.gateway.cidr_block  == "10.0.20.0/24",
      aws_subnet.web.cidr_block      == "10.1.10.0/24",
      aws_subnet.app.cidr_block      == "10.1.20.0/24",
      aws_subnet.data.cidr_block     == "10.1.30.0/24"
    ])
    error_message = "One or more Subnet CIDR blocks do not match the design."
  }

  assert {
    condition     = aws_nat_gateway.main_nat.subnet_id == aws_subnet.gateway.id
    error_message = "NAT Gateway must be in the Public Gateway subnet."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.internet_attach.transit_gateway_id == aws_ec2_transit_gateway.main-tgw.id
    error_message = "VPC Attachments are not pointing to the correct Transit Gateway."
  }

  assert {
    condition     = anytrue([for r in aws_route_table.public_rt.route : r.gateway_id == aws_internet_gateway.igw.id])
    error_message = "Public Route Table is missing the Internet Gateway route."
  }

  assert {
    condition     = anytrue([for r in aws_route_table.private_rt.route : r.transit_gateway_id == aws_ec2_transit_gateway.main-tgw.id])
    error_message = "Private Route Table is missing the Transit Gateway route."
  }
}