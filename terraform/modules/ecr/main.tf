resource "aws_ecr_repository" "services" {
  for_each = toset(var.repository_names)

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = var.project_name
  }
}
