terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
  }

  # ---------------------------------------------------------------------
  # Backend remoto (Requisito Fase 3): estado nunca fica local.
  # Bucket e (opcionalmente) o lock via S3 nativo (use_lockfile) devem ser
  # criados uma única vez fora deste projeto (bootstrap/), pois o backend
  # não pode depender de um recurso gerenciado por ele mesmo.
  # Substitua os valores abaixo ou rode:
  #   terraform init -backend-config=backend.hcl
  # ---------------------------------------------------------------------
  backend "s3" {
    bucket       = "toogle-master-tfstate" # troque pelo nome do seu bucket (globalmente único)
    key          = "fase3/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # S3 lock nativo (Terraform >= 1.9), dispensa DynamoDB
  }
}

provider "aws" {
  region = var.region
}

# ---------------------------------------------------------------------------
# Kubernetes/Helm providers apontam para o cluster EKS recém-criado, usando
# o AWS CLI (exec plugin) para gerar o token de autenticação - evita salvar
# credenciais estáticas de kubeconfig no state.
# ---------------------------------------------------------------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    }
  }
}
