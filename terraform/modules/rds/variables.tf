variable "project_name" {
  type = string
}

variable "instances" {
  description = "Mapa de instancias RDS a criar: chave = identifier, valor = { service_tag = string }"
  type = map(object({
    service_tag = string
  }))
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "engine_version" {
  type    = string
  default = null
}

variable "username" {
  type    = string
  default = "dbuser"
}

variable "password" {
  type      = string
  sensitive = true
}

variable "db_subnet_group_name" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "publicly_accessible" {
  type    = bool
  default = true
}
