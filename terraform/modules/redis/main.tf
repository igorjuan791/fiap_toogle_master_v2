resource "aws_elasticache_cluster" "main" {
  cluster_id           = var.cluster_id
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = var.parameter_group_name
  port                 = 6379
  subnet_group_name    = var.subnet_group_name
  security_group_ids   = [var.security_group_id]

  tags = {
    Project = var.project_name
  }
}
