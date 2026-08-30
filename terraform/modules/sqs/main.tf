resource "aws_sqs_queue" "events" {
  name                       = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds

  tags = {
    Project = var.project_name
  }
}
