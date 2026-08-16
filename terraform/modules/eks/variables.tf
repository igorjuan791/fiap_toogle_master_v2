variable "project_name" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "toogle-cluster"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "lab_role_arn" {
  description = "ARN of the existing LabRole (AWS Academy) used for both the EKS cluster and the Node Group"
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "nodes_security_group_id" {
  type = string
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}
