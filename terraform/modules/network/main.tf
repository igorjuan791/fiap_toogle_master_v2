############################################
# Network module
# VPC + subnets publicas e privadas + IGW + route tables
############################################

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# ---------------- Subnets publicas ----------------
# Hospedam o EKS (nodes) para manter o fluxo de deploy/seed local da Fase 2
# funcionando sem um NAT Gateway (custo extra em ambiente de estudo/AWS Academy).

resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available.names[each.key]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-${each.key}"
    Project = var.project_name
    Tier    = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------------- Subnets privadas ----------------
# Reservadas para bancos de dados / cache em uma topologia mais segura.
# Sem rota para a Internet (sem NAT Gateway) -- suficiente para RDS/ElastiCache,
# que nao precisam de acesso de saida. Ver variavel `database_subnets_public`
# no modulo raiz para a decisao de onde RDS/Redis efetivamente residem hoje.

resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[each.key]

  tags = {
    Name    = "${var.project_name}-private-${each.key}"
    Project = var.project_name
    Tier    = "private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-private-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ---------------- Security Group compartilhado ----------------

resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  description = "Security group para os microsservicos ToggleMaster (EKS, RDS, Redis)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  dynamic "ingress" {
    for_each = var.allow_public_db_access ? [1] : []
    content {
      description = "PostgreSQL (acesso publico - apenas para seed/debug local, ver README)"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.allow_public_db_access ? [1] : []
    content {
      description = "Redis (acesso publico - apenas para seed/debug local, ver README)"
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    description = "APIs dos microsservicos (ToggleMaster)"
    from_port   = 8001
    to_port     = 8005
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Trafego interno do cluster/node group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${lower(var.project_name)}-db-subnet-group"
  subnet_ids = var.database_subnets_public ? [for s in aws_subnet.public : s.id] : [for s in aws_subnet.private : s.id]

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${lower(var.project_name)}-cache-subnet-group"
  subnet_ids = var.database_subnets_public ? [for s in aws_subnet.public : s.id] : [for s in aws_subnet.private : s.id]

  tags = {
    Name    = "${var.project_name}-cache-subnet-group"
    Project = var.project_name
  }
}
