variable "project_name" {
  type = string
}

variable "cluster_id" {
  description = "Nome literal do cluster Redis (mantido igual a Fase 2 para nao quebrar scripts existentes)"
  type        = string
  default     = "toogle-redis"
}

variable "node_type" {
  type    = string
  default = "cache.t3.medium"
}

variable "parameter_group_name" {
  type    = string
  default = "default.redis7"
}

variable "subnet_group_name" {
  type = string
}

variable "security_group_id" {
  type = string
}
