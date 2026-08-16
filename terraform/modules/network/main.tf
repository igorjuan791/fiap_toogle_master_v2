data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${lower(var.project_name)}-vpc"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${lower(var.project_name)}-igw"
    Project = var.project_name
  }
}

# ---------------------------------------------------------------------------
# Public Subnets (NAT Gateway, Load Balancers/Ingress)
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${lower(var.project_name)}-public-${local.azs[count.index]}"
    Project                  = var.project_name
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${lower(var.project_name)}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Private Subnets (EKS Nodes, RDS, ElastiCache)
# ---------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name                              = "${lower(var.project_name)}-private-${local.azs[count.index]}"
    Project                           = var.project_name
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ---------------------------------------------------------------------------
# NAT Gateway(s) - allow the private subnets to reach the internet
# (ECR pulls, package downloads, etc.). Single NAT by default to control cost.
# ---------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name    = "${lower(var.project_name)}-nat-eip-${count.index}"
    Project = var.project_name
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name    = "${lower(var.project_name)}-nat-${count.index}"
    Project = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name    = "${lower(var.project_name)}-private-rt-${count.index}"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------
resource "aws_security_group" "nodes" {
  name        = "${lower(var.project_name)}-nodes-sg"
  description = "Security group shared by EKS nodes and internal services"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Node to node"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Ingress controller / NodePort range from within the VPC"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${lower(var.project_name)}-nodes-sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "data" {
  name        = "${lower(var.project_name)}-data-sg"
  description = "Security group for RDS/ElastiCache - only reachable from the EKS nodes SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.nodes.id]
  }

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${lower(var.project_name)}-data-sg"
    Project = var.project_name
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${lower(var.project_name)}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name    = "${lower(var.project_name)}-db-subnet-group"
    Project = var.project_name
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${lower(var.project_name)}-cache-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}
