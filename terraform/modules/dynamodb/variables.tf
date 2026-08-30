variable "project_name" {
  type = string
}

variable "table_name" {
  type    = string
  default = "ToggleMasterAnalytics"
}

variable "hash_key" {
  type    = string
  default = "event_id"
}
