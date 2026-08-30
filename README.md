# ToggleMaster - Fase 2 + Fase 3

Este projeto é a evolução do ToggleMaster para uma arquitetura de microsserviços distribuídos (Fase 2) e, na **Fase 3**, para uma operação totalmente automatizada com IaC, pipelines de CI/DevSecOps e entrega contínua via GitOps/ArgoCD.

## 🆕 Fase 3 — IaC, CI/CD DevSecOps e GitOps

| O que | Onde | Doc |
|---|---|---|
| Infraestrutura como código (módulos Terraform + backend remoto S3) | `terraform/` | [terraform/README.md](terraform/README.md) |
| Pipelines de CI + DevSecOps (build, lint, SCA, SAST, build & push da imagem) | `.github/workflows/` | [docs/CI_SETUP.md](docs/CI_SETUP.md) |
| Entrega contínua via GitOps (manifestos + ArgoCD) | `gitops/` | [gitops/README.md](gitops/README.md) |
| Roteiro para o vídeo de demonstração | `docs/DEMO_SCRIPT.md` | [docs/DEMO_SCRIPT.md](docs/DEMO_SCRIPT.md) |
| Template do relatório de entrega | `docs/RELATORIO_TEMPLATE.md` | [docs/RELATORIO_TEMPLATE.md](docs/RELATORIO_TEMPLATE.md) |

Fluxo resumido: `terraform apply` sobe VPC/EKS/RDS/Redis/DynamoDB/SQS/ECR →
push na `main` de um microsserviço dispara o pipeline (build → lint → SCA →
SAST → build/scan/push da imagem no ECR) → o próprio pipeline atualiza a tag
da imagem em `gitops/<serviço>/deployment.yaml` → o **ArgoCD**, instalado no
EKS, detecta a mudança e sincroniza o cluster automaticamente.

A pasta `k8s/` (deploy manual/Helm) e os scripts em `aws-infra/` continuam
funcionando e são úteis para debug local — mas o caminho "oficial" de
entrega da Fase 3 é `terraform/` + `.github/workflows/` + `gitops/`.

## 🚀 Como Rodar Localmente

### 1. Aplicar Patches e Preparar Ambiente
Os microsserviços são submódulos. Aplique as customizações necessárias:
```bash
./install.sh
```

### 2. Subir o Ecossistema com Docker Compose
O `docker-compose.yaml` foi configurado para subir todos os 5 microsserviços e as dependências locais:
- **2 instâncias PostgreSQL** (Auth e Main)
- **Redis**
- **DynamoDB Local**
- **LocalStack** (para SQS)
- **AWS Setup** (criação automática de filas e tabelas locais)

Execute:
```bash
docker compose up --build
```

### 3. Verificar Saúde dos Serviços
Após o build e inicialização, execute o smoke test:
```bash
./smoke-test.sh
```

## 📦 Estrutura de Microsserviços
- **auth-service (Go):** Gerencia chaves de API. (Porta 8001)
- **flag-service (Python):** CRUD de feature flags. (Porta 8002)
- **targeting-service (Python):** Regras de segmentação. (Porta 8003)
- **evaluation-service (Go):** "Hot path" de alta performance. (Porta 8004)
- **analytics-service (Python):** Processador de eventos assíncronos. (Porta 8005)

## ☁️ Infraestrutura AWS (Cloud)

O projeto agora suporta o provisionamento automatizado da infraestrutura na AWS (RDS, ECR, SQS, DynamoDB, Redis e EKS) utilizando **Terraform**. Você tem dois caminhos para subir o ambiente:

### Opção 1: Script Automatizado (Recomendado)
Para uma experiência de "um clique" que provisiona a infraestrutura, faz o build das imagens, popula o banco de dados e configura os manifestos Kubernetes:

```bash
chmod +x setup-cloud.sh
./setup-cloud.sh
```
*Este script automatiza o Terraform + Build/Push + Seeding + Patching do K8s.*

### Opção 2: Terraform Manual (IaC)
Se preferir gerenciar os recursos manualmente (fluxo completo, com backend remoto, em [terraform/README.md](terraform/README.md)):

1. Acesse a pasta: `cd terraform`
2. (uma vez) Crie o bucket S3 do state com `terraform/bootstrap` e copie `backend.hcl.example` para `backend.hcl`.
3. Configure suas variáveis no arquivo `terraform.tfvars` (use o `.example` como base).
4. Execute os comandos:
```bash
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## ☸️ Kubernetes (EKS)
Os manifestos para implantação no Kubernetes estão na pasta `/k8s`. Eles incluem:
- **Namespace:** `toogle-master`
- **Deployments:** Com limites de recursos e probes de saúde.
- **Services:** ClusterIP para comunicação interna.
- **Ingress:** Nginx Ingress para roteamento externo.
- **HPA:** Escalabilidade automática para `evaluation-service` e `analytics-service`.

### Como Aplicar (Kubernetes Estático):
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
# Ingress controller que criará um endpoint através de um loadbalancer
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

### Como Aplicar (Helm):
O projeto agora inclui um **Helm Chart** em `k8s/charts/toogle-master` para facilitar o deploy e a configuração.

1. Instale o chart:
```bash
helm install toogle-master ./k8s/charts/toogle-master -n toogle-master --create-namespace
```

2. Atualize configurações (como AccountID da AWS) via `values.yaml`:
```bash
helm upgrade toogle-master ./k8s/charts/toogle-master -n toogle-master --set accountID="SEU_ID_AWS"
```

## 🛠️ Detalhes de Implementação
- **Dockerfiles Otimizados:** Utilizam multi-stage builds para reduzir o tamanho das imagens e aumentar a segurança.
- **Resiliência:** Configuração de Readiness e Liveness Probes em todos os serviços.
- **Escalabilidade:** HPAs configurados para lidar com picos de tráfego e processamento de mensagens.
- **LocalStack Support:** Os serviços foram adaptados para aceitar `AWS_ENDPOINT_URL`, permitindo testes completos de SQS/DynamoDB localmente.
