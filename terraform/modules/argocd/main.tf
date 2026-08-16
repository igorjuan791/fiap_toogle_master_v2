# Installs ArgoCD on the EKS cluster via the official Helm chart.
# Runs after the cluster/node group exist (see root main.tf providers).

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Pull-based GitOps: ArgoCD runs inside the cluster and polls/watches the
  # GitOps repo itself - nothing ever pushes credentials or kubeconfig out.
  set {
    name  = "configs.params.server\\.insecure"
    value = "true" # simplifies port-forward/ALB without extra TLS setup for the challenge
  }

  dynamic "set" {
    for_each = var.argocd_admin_password_bcrypt != "" ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.argocd_admin_password_bcrypt
    }
  }
}

output "namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}
