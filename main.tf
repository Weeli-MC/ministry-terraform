
#1. Provider
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.0"
        }
    }
}

provider "aws" {
    region = "ap-southeast-1"
  
}


#2 Internet VPC
resource "aws_vpc" "internet_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = {Name = "Internet-VPC"}
  
}

#3 Workload VPC
resource "aws_vpc" "workload_vpc" {
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true
  tags = {Name = "Workload-VPC"}
}



#4 Transit Gateway
resource "aws_ec2_transit_gateway" "main-tgw" {
  description = "Connects the Internet and Workload VPCs"
  tags = {Name = "Main-TGW"}
}

#5 Attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "internet_attach" {
  subnet_ids = [aws_subnet.internet_tgw_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.main-tgw.id
  vpc_id = aws_vpc.internet_vpc.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "workload_attach" {
    subnet_ids = [aws_subnet.workload_tgw_subnet.id]
    transit_gateway_id = aws_ec2_transit_gateway.main-tgw.id
    vpc_id = aws_vpc.workload_vpc.id
  
}


//Internet Subnets

resource "aws_subnet" "firewall" {
  vpc_id = aws_vpc.internet_vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "ap-southeast-1b"
  tags = {Name = "Firewall-Subnet"}
}

resource "aws_subnet" "gateway" {
    vpc_id            = aws_vpc.internet_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "Gateway-Subnet" }
}


//Workload Subnets
resource "aws_subnet" "web" {
  vpc_id            = aws_vpc.workload_vpc.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "Web-Subnet" }
}

resource "aws_subnet" "app" {
  vpc_id            = aws_vpc.workload_vpc.id
  cidr_block        = "10.1.20.0/24"
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "App-Subnet" }
}

resource "aws_subnet" "data" {
  vpc_id            = aws_vpc.workload_vpc.id
  cidr_block        = "10.1.30.0/24"
  availability_zone = "ap-southeast-1b"
  tags              = { Name = "Data-Subnet" }
}

resource "aws_subnet" "internet_tgw_subnet" {
  vpc_id     = aws_vpc.internet_vpc.id
  cidr_block = "10.0.100.0/24"
  tags       = { Name = "Internet-TGW-Subnet" }
}

resource "aws_subnet" "workload_tgw_subnet" {
  vpc_id     = aws_vpc.workload_vpc.id
  cidr_block = "10.1.100.0/24"
  tags       = { Name = "Workload-TGW-Subnet" }
}



//Internet Gateway
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
    subnet_id = aws_subnet.firewall.id
    route_table_id = aws_route_table.public_rt.id
}


# Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.internet_vpc.id
  description = "Allow HTTP traffic from everywhere"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "external_alb" {
  name               = "external-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.gateway.id, aws_subnet.firewall.id]
}


//NAT Gateway
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
    cidr_block     = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.main-tgw.id
  }

  tags = { Name = "Private-Route-Table" }
}

resource "aws_route_table_association" "app_private" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "data_private" {
  subnet_id      = aws_subnet.data.id
  route_table_id = aws_route_table.private_rt.id
}


//Database
resource "aws_db_subnet_group" "data_subnets" {
  name       = "main-data-subnets"
  subnet_ids = [aws_subnet.data.id, aws_subnet.app.id] 
  tags       = { Name = "Aurora-Subnet-Group" }
}

resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  vpc_id      = aws_vpc.workload_vpc.id
  description = "Allow traffic from the App only"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks = [aws_vpc.internet_vpc.cidr_block]
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "ministry-family-db"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "15"
  database_name           = "ministryfamily"
  master_username         = "adminuser"
  master_password         = "SecurePassword123!"
  db_subnet_group_name    = aws_db_subnet_group.data_subnets.name
  vpc_security_group_ids  = [aws_security_group.database_sg.id]
  skip_final_snapshot     = true

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
}


output "alb_dns_name" {
  value       = aws_lb.external_alb.dns_name
  description = "public url"
}

output "nat_gateway_ip" {
  value       = aws_nat_gateway.main_nat.private_ip
  description = "IP of NAT Gateway"
}

output "database_endpoint" {
  value       = aws_rds_cluster.aurora_cluster.endpoint
  description = "Aurora database"
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "503 Service Unavailable! The service you requested is not available at this time."
      status_code  = "503"
    }
  }
}