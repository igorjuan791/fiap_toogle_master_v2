variable "project_name" {
  type = string
}

variable "cluster_name" {
  description = "Nome literal do cluster EKS (mantido igual a Fase 2 para nao quebrar scripts existentes)"
  type        = string
  default     = "toogle-cluster"
}

variable "node_group_name" {
  type    = string
  default = "toogle-nodes"
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "use_lab_role" {
  description = "true = AWS Academy (usa LabRole existente via data source, nao cria IAM); false = conta pessoal (cria roles dedicadas via Terraform)"
  type        = bool
  default     = true
}

variable "lab_role_name" {
  description = "Nome da role do AWS Academy (ex: LabRole)"
  type        = string
  default     = "LabRole"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
