#!/bin/bash
# Instala o ArgoCD no cluster EKS via Helm e aplica as 6 Applications
# (namespace/ingress compartilhados + 5 microsservicos).
#
# Pre-requisitos:
#   - kubectl configurado para o cluster EKS
#     (aws eks update-kubeconfig --region us-east-1 --name toogle-cluster)
#   - helm instalado
#
# Uso:
#   ./install.sh [URL_DO_SEU_REPO_GIT]
# Se nao passar URL, usa o remote "origin" do repositorio atual.

set -e

REPO_URL="${1:-$(git config --get remote.origin.url)}"
if [ -z "$REPO_URL" ]; then
  echo "Nao foi possivel detectar a URL do repositorio Git. Passe como argumento:"
  echo "  ./install.sh https://github.com/SEU_USUARIO/SEU_REPO.git"
  exit 1
fi
echo "Usando repositorio GitOps: $REPO_URL"

echo "--------------------------------------------------------"
echo "1) Instalando ArgoCD via Helm no namespace 'argocd'..."
echo "--------------------------------------------------------"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --wait

echo "--------------------------------------------------------"
echo "2) Aplicando as ArgoCD Applications (aponta para $REPO_URL)..."
echo "--------------------------------------------------------"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for f in "$DIR"/applications/*.yaml; do
  sed "s#__REPO_URL__#${REPO_URL}#g" "$f" | kubectl apply -f -
done

echo "--------------------------------------------------------"
echo "3) Pronto! Para acessar a UI do ArgoCD:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Usuario: admin"
echo "   Senha:   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "--------------------------------------------------------"
