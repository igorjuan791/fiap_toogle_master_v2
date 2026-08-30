variable "project_name" {
  type = string
}

variable "queue_name" {
  type    = string
  default = "toggle-events"
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}
