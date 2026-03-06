output "alb_dns_name" {
  value       = module.compute.alb_dns_name
  description = "public url"
}

output "nat_gateway_ip" {
  value       = module.networking.nat_gateway_private_ip
  description = "IP of NAT Gateway"
}

output "database_endpoint" {
  value       = module.database.database_endpoint
  description = "Aurora database"
}
