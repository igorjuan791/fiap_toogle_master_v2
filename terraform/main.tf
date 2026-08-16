data "aws_iam_role" "lab_role" {
  name = var.lab_role_name
}

module "network" {
  source       = "./modules/network"
  project_name = var.project_name
}

module "eks" {
  source = "./modules/eks"

  project_name             = var.project_name
  lab_role_arn             = data.aws_iam_role.lab_role.arn
  public_subnet_ids        = module.network.public_subnet_ids
  private_subnet_ids       = module.network.private_subnet_ids
  nodes_security_group_id  = module.network.nodes_security_group_id
}

module "database" {
  source = "./modules/database"

  project_name                  = var.project_name
  db_subnet_group_name          = module.network.db_subnet_group_name
  elasticache_subnet_group_name = module.network.elasticache_subnet_group_name
  data_security_group_id        = module.network.data_security_group_id
  db_password                   = var.db_password
}

module "messaging" {
  source       = "./modules/messaging"
  project_name = var.project_name
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

# O módulo do ArgoCD depende do cluster EKS já estar pronto e acessível.
# Recomendação: primeiro "terraform apply" com install_argocd=false para
# subir VPC/EKS/DBs, depois "terraform apply -var install_argocd=true".
# Isso evita o problema clássico do provider kubernetes/helm tentando se
# autenticar num cluster que ainda não existe no mesmo plan.
module "argocd" {
  source = "./modules/argocd"
  count  = var.install_argocd ? 1 : 0

  depends_on = [module.eks]
}
