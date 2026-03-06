output "internet_vpc_id" {
  value = aws_vpc.internet_vpc.id
}

output "workload_vpc_id" {
  value = aws_vpc.workload_vpc.id
}

output "internet_vpc_cidr_block" {
  value = aws_vpc.internet_vpc.cidr_block
}

output "gateway_subnet_id" {
  value = aws_subnet.gateway.id
}

output "firewall_subnet_id" {
  value = aws_subnet.firewall.id
}

output "app_subnet_id" {
  value = aws_subnet.app.id
}

output "data_subnet_id" {
  value = aws_subnet.data.id
}

output "nat_gateway_private_ip" {
  value = aws_nat_gateway.main_nat.private_ip
}
