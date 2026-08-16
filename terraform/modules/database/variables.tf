variable "project_name" {
  type = string
}

variable "db_subnet_group_name" {
  type = string
}

variable "elasticache_subnet_group_name" {
  type = string
}

variable "data_security_group_id" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.medium"
}

variable "dynamodb_table_name" {
  type    = string
  default = "ToggleMasterAnalytics"
}
