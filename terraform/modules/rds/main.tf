############################################
# RDS module
# Provisiona N instancias PostgreSQL a partir de var.instances
############################################

resource "aws_db_instance" "this" {
  for_each = var.instances

  identifier             = each.key
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  engine                 = "postgres"
  engine_version         = var.engine_version
  username               = var.username
  password               = var.password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = var.publicly_accessible
  skip_final_snapshot    = true

  tags = {
    Project = var.project_name
    Service = each.value.service_tag
  }
}
