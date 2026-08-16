output "rds_auth_endpoint" {
  value = aws_db_instance.auth_db.endpoint
}

output "rds_main_endpoint" {
  value = aws_db_instance.main_db.endpoint
}

output "rds_targeting_endpoint" {
  value = aws_db_instance.targeting_db.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.analytics.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.analytics.arn
}
