variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "lab_role_name" {
  description = "The name of the existing IAM role to reuse (AWS Academy/Lab). Não criamos Roles/Policies via Terraform quando usando Academy."
  type        = string
  default     = "LabRole"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "ToogleMaster"
}

variable "install_argocd" {
  description = "Se true, instala o ArgoCD via Helm dentro deste apply (requer que o cluster já exista - normalmente rodado em um 2º apply)."
  type        = bool
  default     = false
}
