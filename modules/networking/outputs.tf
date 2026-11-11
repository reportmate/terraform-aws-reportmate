output "vpc_id" {
  description = "VPC ID (created, or the existing VPC when existing_vpc_id is set)"
  value       = local.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs owned by this module"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs owned by this module"
  value       = local.private_subnet_ids
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = local.vpc_cidr_block
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs: the module's own (one or N depending on enable_multi_az_nat), or the existing NAT gateway in existing-VPC mode."
  value       = local.nat_gateway_ids
}
