variable "namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  description = "argo-cd Helm chart version"
  type        = string
  default     = "7.7.11"
}

variable "argocd_admin_password_bcrypt" {
  description = "Bcrypt hash of the ArgoCD admin password (leave empty to keep the chart's auto-generated secret)"
  type        = string
  default     = ""
}
