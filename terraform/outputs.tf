output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

# Nomes mantidos identicos aos da Fase 2 (deploy-helper.sh depende deles).
output "rds_auth_endpoint" {
  value = module.rds.endpoints["auth-db"]
}

output "rds_main_endpoint" {
  value = module.rds.endpoints["main-db"]
}

output "rds_flag_endpoint" {
  value = module.rds.endpoints["main-db"]
}

output "rds_targeting_endpoint" {
  value = module.rds.endpoints["targeting-db"]
}

output "redis_endpoint" {
  value = module.redis.endpoint
}

output "sqs_url" {
  value = module.sqs.queue_url
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
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
