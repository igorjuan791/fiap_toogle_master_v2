output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "rds_auth_endpoint" {
  value = module.database.rds_auth_endpoint
}

output "rds_main_endpoint" {
  value = module.database.rds_main_endpoint
}

output "rds_targeting_endpoint" {
  value = module.database.rds_targeting_endpoint
}

output "redis_endpoint" {
  value = module.database.redis_endpoint
}

output "dynamodb_table_name" {
  value = module.database.dynamodb_table_name
}

output "sqs_url" {
  value = module.messaging.queue_url
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "db_password" {
  value     = var.db_password
  sensitive = true
}

output "region" {
  value = var.region
}
