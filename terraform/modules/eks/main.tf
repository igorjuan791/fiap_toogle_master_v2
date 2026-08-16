resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.lab_role_arn
  version  = var.kubernetes_version

  vpc_config {
    # Control plane ENIs span both public and private subnets so the
    # public endpoint keeps working while nodes stay private.
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_public_access  = true
    endpoint_private_access = true
    security_group_ids      = [var.nodes_security_group_id]
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "toogle-nodes"
  node_role_arn   = var.lab_role_arn
  # Nodes only live in private subnets - no public IPs, egress via NAT Gateway.
  subnet_ids = var.private_subnet_ids
  version    = var.kubernetes_version

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.node_instance_types
  capacity_type  = var.node_capacity_type

  tags = {
    Project = var.project_name
  }
}
