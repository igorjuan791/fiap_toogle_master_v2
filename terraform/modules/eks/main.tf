############################################
# EKS module
# Cluster + Node Group usando a LabRole (AWS Academy) via data source,
# ou uma role dedicada quando use_lab_role = false (conta pessoal).
############################################

data "aws_iam_role" "lab_role" {
  count = var.use_lab_role ? 1 : 0
  name  = var.lab_role_name
}

# ---- Roles proprias (apenas quando NAO estamos no AWS Academy) ----

data "aws_iam_policy_document" "eks_assume" {
  count = var.use_lab_role ? 0 : 1
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  count              = var.use_lab_role ? 0 : 1
  name               = "${var.project_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume[0].json
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  count      = var.use_lab_role ? 0 : 1
  role       = aws_iam_role.cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "node_assume" {
  count = var.use_lab_role ? 0 : 1
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  count              = var.use_lab_role ? 0 : 1
  name               = "${var.project_name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume[0].json
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  count      = var.use_lab_role ? 0 : 1
  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  count      = var.use_lab_role ? 0 : 1
  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  count      = var.use_lab_role ? 0 : 1
  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

locals {
  cluster_role_arn = var.use_lab_role ? data.aws_iam_role.lab_role[0].arn : aws_iam_role.cluster[0].arn
  node_role_arn    = var.use_lab_role ? data.aws_iam_role.lab_role[0].arn : aws_iam_role.node[0].arn
}

# ---- Cluster ----

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = local.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = true
    security_group_ids      = [var.security_group_id]
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = local.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = var.instance_types
  capacity_type  = "ON_DEMAND"

  tags = {
    Project = var.project_name
  }
}
