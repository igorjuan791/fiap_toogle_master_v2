############################################
# Root module: instancia os modulos e liga as saidas de um no input do outro.
############################################

module "network" {
  source = "./modules/network"

  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  database_subnets_public = var.database_subnets_public
  allow_public_db_access  = var.allow_public_db_access
}

module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  cluster_name       = var.eks_cluster_name
  node_group_name    = var.eks_node_group_name
  subnet_ids         = module.network.public_subnet_ids
  security_group_id  = module.network.security_group_id
  use_lab_role       = var.use_lab_role
  lab_role_name      = var.lab_role_name
  kubernetes_version = var.kubernetes_version
  desired_size       = var.eks_desired_size
  min_size           = var.eks_min_size
  max_size           = var.eks_max_size
  instance_types     = var.eks_instance_types
}

module "rds" {
  source = "./modules/rds"

  project_name = var.project_name
  # Identifiers mantidos iguais a Fase 2 (auth-db/main-db/targeting-db) para
  # nao quebrar aws-infra/generate-summary.sh, que consulta o RDS por nome.
  instances = {
    "auth-db"      = { service_tag = "Auth" }
    "main-db"      = { service_tag = "Flag" }
    "targeting-db" = { service_tag = "Targeting" }
  }
  password             = var.db_password
  db_subnet_group_name = module.network.db_subnet_group_name
  security_group_id    = module.network.security_group_id
  publicly_accessible  = var.database_subnets_public
}

module "redis" {
  source = "./modules/redis"

  project_name       = var.project_name
  cluster_id         = var.redis_cluster_id
  subnet_group_name  = module.network.elasticache_subnet_group_name
  security_group_id  = module.network.security_group_id
}

module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  table_name   = var.dynamodb_table_name
}

module "sqs" {
  source = "./modules/sqs"

  project_name = var.project_name
  queue_name   = var.sqs_queue_name
}

module "ecr" {
  source = "./modules/ecr"

  project_name      = var.project_name
  repository_names  = var.ecr_repository_names
}
