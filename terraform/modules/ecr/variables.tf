variable "project_name" {
  type = string
}

variable "repository_names" {
  type    = list(string)
  default = ["analytics-service", "auth-service", "evaluation-service", "flag-service", "targeting-service"]
}
