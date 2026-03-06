# Internet VPC
resource "aws_vpc" "internet_vpc" {
  cidr_block           = var.internet_vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "Internet-VPC" }
}

# Workload VPC
resource "aws_vpc" "workload_vpc" {
  cidr_block           = var.workload_vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "Workload-VPC" }
}

# Transit Gateway
resource "aws_ec2_transit_gateway" "main-tgw" {
  description = "Connects the Internet and Workload VPCs"
  tags        = { Name = "Main-TGW" }
}

# TGW Attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "internet_attach" {
  subnet_ids         = [aws_subnet.internet_tgw_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.main-tgw.id
  vpc_id             = aws_vpc.internet_vpc.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "workload_attach" {
  subnet_ids         = [aws_subnet.workload_tgw_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.main-tgw.id
  vpc_id             = aws_vpc.workload_vpc.id
}

# Internet Subnets
resource "aws_subnet" "firewall" {
  vpc_id            = aws_vpc.internet_vpc.id
  cidr_block        = var.firewall_subnet_cidr
  availability_zone = "ap-southeast-1b"
  tags              = { Name = "Firewall-Subnet" }
}

resource "aws_subnet" "gateway" {
  vpc_id            = aws_vpc.internet_vpc.id
  cidr_block        = var.gateway_subnet_cidr
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "Gateway-Subnet" }
}

# Workload Subnets
resource "aws_subnet" "web" {
  vpc_id            = aws_vpc.workload_vpc.id
  cidr_block        = var.web_subnet_cidr
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "Web-Subnet" }
}

resource "aws_subnet" "app" {
  vpc_id            = aws_vpc.workload_vpc.id
  cidr_block        = var.app_subnet_cidr
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "App-Subnet" }
}

resource "aws_subnet" "data" {
  vpc_id            = aws_vpc.workload_vpc.id
  cidr_block        = var.data_subnet_cidr
  availability_zone = "ap-southeast-1b"
  tags              = { Name = "Data-Subnet" }
}

resource "aws_subnet" "internet_tgw_subnet" {
  vpc_id     = aws_vpc.internet_vpc.id
  cidr_block = var.internet_tgw_subnet_cidr
  tags       = { Name = "Internet-TGW-Subnet" }
}

resource "aws_subnet" "workload_tgw_subnet" {
  vpc_id     = aws_vpc.workload_vpc.id
  cidr_block = var.workload_tgw_subnet_cidr
  tags       = { Name = "Workload-TGW-Subnet" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.internet_vpc.id
  tags   = { Name = "Main-IGW" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.internet_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "Public-Route-Table" }
}

resource "aws_route_table_association" "gateway_attach" {
  subnet_id      = aws_subnet.gateway.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "firewall_association" {
  subnet_id      = aws_subnet.firewall.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "NAT-EIP" }
}

resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.gateway.id
  tags          = { Name = "Main-NAT-Gateway" }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.workload_vpc.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.main-tgw.id
  }

  tags = { Name = "Private-Route-Table" }
}

resource "aws_route" "internet_to_workload" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = var.workload_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main-tgw.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.internet_attach]
}

resource "aws_route_table_association" "app_private" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "data_private" {
  subnet_id      = aws_subnet.data.id
  route_table_id = aws_route_table.private_rt.id
}
