variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto para tags"
  type        = string
  default     = "ToggleMaster"
}

variable "db_password" {
  description = "Senha mestra dos bancos RDS"
  type        = string
  sensitive   = true
}

# ---------------- AWS Academy / LabRole ----------------

variable "use_lab_role" {
  description = "true = AWS Academy (Opcao A do desafio: nao cria Roles/Policies IAM, usa a LabRole existente). false = conta pessoal (Opcao B: cria roles dedicadas)."
  type        = bool
  default     = true
}

variable "lab_role_name" {
  description = "Nome da role do AWS Academy (ex: LabRole)"
  type        = string
  default     = "LabRole"
}

# ---------------- Network ----------------

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnets_public" {
  description = "true = RDS/Redis nas subnets publicas (fluxo de seed local da Fase 2 continua funcionando sem alteracao). false = RDS/Redis nas subnets privadas (mais seguro; requer seed via Job dentro do cluster)."
  type        = bool
  default     = true
}

variable "allow_public_db_access" {
  type    = bool
  default = true
}

# ---------------- EKS ----------------

variable "eks_cluster_name" {
  type    = string
  default = "toogle-cluster"
}

variable "eks_node_group_name" {
  type    = string
  default = "toogle-nodes"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "eks_desired_size" {
  type    = number
  default = 2
}

variable "eks_min_size" {
  type    = number
  default = 1
}

variable "eks_max_size" {
  type    = number
  default = 3
}

variable "eks_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

# ---------------- Redis ----------------

variable "redis_cluster_id" {
  type    = string
  default = "toogle-redis"
}

# ---------------- DynamoDB ----------------

variable "dynamodb_table_name" {
  description = "Nome da tabela de analytics (Requisito Fase 3: ToggleMasterAnalytics)"
  type        = string
  default     = "ToggleMasterAnalytics"
}

# ---------------- SQS ----------------

variable "sqs_queue_name" {
  type    = string
  default = "toogle-events"
}

# ---------------- ECR ----------------

variable "ecr_repository_names" {
  type    = list(string)
  default = ["analytics-service", "auth-service", "evaluation-service", "flag-service", "targeting-service"]
}
