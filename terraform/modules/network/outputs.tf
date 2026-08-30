output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "database_subnet_ids" {
  description = "Subnets efetivamente usadas por RDS/ElastiCache (publicas ou privadas conforme database_subnets_public)"
  value       = var.database_subnets_public ? [for s in aws_subnet.public : s.id] : [for s in aws_subnet.private : s.id]
}

output "security_group_id" {
  value = aws_security_group.main.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.main.name
}

output "elasticache_subnet_group_name" {
  value = aws_elasticache_subnet_group.main.name
}
