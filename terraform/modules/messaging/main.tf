variable "project_name" {
  type = string
}

variable "queue_name" {
  type    = string
  default = "toogle-events"
}

resource "aws_sqs_queue" "events_dlq" {
  name                      = "${var.queue_name}-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Project = var.project_name
  }
}

resource "aws_sqs_queue" "events" {
  name                       = var.queue_name
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.events_dlq.arn
    maxReceiveCount     = 5
  })

  tags = {
    Project = var.project_name
  }
}

output "queue_url" {
  value = aws_sqs_queue.events.url
}

output "queue_arn" {
  value = aws_sqs_queue.events.arn
}
