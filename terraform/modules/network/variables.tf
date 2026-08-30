variable "project_name" {
  description = "Nome do projeto, usado em tags e nomes de recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para as subnets publicas (uma por AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para as subnets privadas (uma por AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnets_public" {
  description = "Se true, RDS/ElastiCache ficam nas subnets publicas (necessario para o fluxo de seed local da Fase 2 via docker). Se false, ficam nas subnets privadas (mais seguro, recomendado para producao)."
  type        = bool
  default     = true
}

variable "allow_public_db_access" {
  description = "Se true, abre 5432/6379 para 0.0.0.0/0 (necessario apenas quando database_subnets_public=true e voce precisa rodar seed-databases.sh a partir da sua maquina local)."
  type        = bool
  default     = true
}
