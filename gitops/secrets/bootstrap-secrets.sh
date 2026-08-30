#!/bin/bash
# Cria os Secrets do Kubernetes usados pelos 5 microsserviços.
#
# Por que isso NAO fica dentro do fluxo GitOps/ArgoCD? Porque o repositorio de
# GitOps e publico/versionado, e nao deve conter credenciais em texto plano.
# Este script roda UMA VEZ (ou sempre que uma credencial mudar), fora do
# ArgoCD, criando os Secrets diretamente no cluster. Os Deployments em
# gitops/<service>/deployment.yaml apenas referenciam esses Secrets pelo
# nome (secretKeyRef) -- e isso sim e versionado e sincronizado pelo ArgoCD.
#
# Uso:
#   1. cd gitops/secrets
#   2. cp auth.env.example auth.env   (e assim para os outros 4)
#   3. Preencha os valores reais (pode usar `terraform output` na raiz do
#      projeto para pegar os endpoints de RDS/Redis/SQS)
#   4. ./bootstrap-secrets.sh
#
# Os arquivos *.env (sem .example) estao no .gitignore e nunca devem ser
# commitados.

set -e

NAMESPACE="toogle-master"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

create_secret() {
  local name=$1
  local envfile=$2
  if [ ! -f "$DIR/$envfile" ]; then
    echo "AVISO: $envfile nao encontrado, pulando $name (copie o .example e preencha)."
    return
  fi
  echo "Criando/atualizando secret $name a partir de $envfile..."
  kubectl create secret generic "$name" \
    --namespace "$NAMESPACE" \
    --from-env-file="$DIR/$envfile" \
    --dry-run=client -o yaml | kubectl apply -f -
}

create_secret "auth-service-secret" "auth.env"
create_secret "flag-service-secret" "flag.env"
create_secret "targeting-service-secret" "targeting.env"
create_secret "evaluation-service-secret" "evaluation.env"
create_secret "analytics-service-secret" "analytics.env"

echo "--------------------------------------------------------"
echo "Secrets aplicados no namespace $NAMESPACE."
echo "--------------------------------------------------------"
