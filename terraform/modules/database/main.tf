# ---------------------------------------------------------------------------
# RDS PostgreSQL (3 instances, as required: auth, main/flag+evaluation, targeting)
# ---------------------------------------------------------------------------
resource "aws_db_instance" "auth_db" {
  identifier             = "auth-db"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  engine                 = "postgres"
  username               = "dbuser"
  password               = var.db_password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.data_security_group_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true

  tags = {
    Project = var.project_name
    Service = "Auth"
  }
}

resource "aws_db_instance" "main_db" {
  identifier             = "main-db"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  engine                 = "postgres"
  username               = "dbuser"
  password               = var.db_password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.data_security_group_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true

  tags = {
    Project = var.project_name
    Service = "Flag"
  }
}

resource "aws_db_instance" "targeting_db" {
  identifier             = "targeting-db"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  engine                 = "postgres"
  username               = "dbuser"
  password               = var.db_password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.data_security_group_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true

  tags = {
    Project = var.project_name
    Service = "Targeting"
  }
}

# ---------------------------------------------------------------------------
# ElastiCache (Redis)
# ---------------------------------------------------------------------------
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "toogle-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = var.elasticache_subnet_group_name
  security_group_ids   = [var.data_security_group_id]

  tags = {
    Project = var.project_name
  }
}

# ---------------------------------------------------------------------------
# DynamoDB - analytics events table
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "analytics" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}
