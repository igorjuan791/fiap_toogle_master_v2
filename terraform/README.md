# Infraestrutura como Código - ToogleMaster (Fase 3)

Projeto Terraform modularizado que provisiona toda a infraestrutura AWS dos 5
microsserviços do ToggleMaster (auth, flag, targeting, evaluation, analytics).

## Estrutura

```
terraform/
├── bootstrap/         # cria o bucket S3 do backend remoto (roda 1x, estado local)
├── modules/
│   ├── network/        # VPC, subnets públicas/privadas, IGW, NAT, route tables, SGs
│   ├── eks/             # Cluster EKS + Node Group (usa a LabRole via data source)
│   ├── database/        # 3x RDS PostgreSQL, ElastiCache (Redis), DynamoDB
│   ├── messaging/        # SQS (+ DLQ)
│   ├── ecr/               # 5 repositórios ECR com lifecycle policy
│   └── argocd/             # Instalação do ArgoCD via Helm (pull-based GitOps)
├── main.tf             # conecta os módulos
├── providers.tf         # backend S3 + providers aws/kubernetes/helm
├── variables.tf
└── outputs.tf
```

## Ambiente AWS Academy

Este projeto **não cria Roles/Policies de IAM**. O EKS e o Node Group usam a
`LabRole` existente, importada via `data "aws_iam_role"` (`network`/`main.tf`).
Se vocês migrarem para uma conta pessoal, basta trocar essa data source por
`aws_iam_role`/`aws_iam_role_policy_attachment` reais (ver comentário em
`variables.tf`).

## Passo a passo

### 1. Bootstrap do backend remoto (rodar uma única vez)

```bash
cd terraform/bootstrap
terraform init
terraform apply -var bucket_name=SEU-BUCKET-UNICO-GLOBALMENTE
```

Depois, edite `terraform/providers.tf` e troque o `bucket` do backend `s3`
pelo nome escolhido.

### 2. Infraestrutura principal (VPC, EKS, bancos, mensageria, ECR)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edite a senha do banco
terraform init
terraform plan
terraform apply
```

### 3. ArgoCD (2º apply, depois que o cluster já existe)

```bash
terraform apply -var install_argocd=true
```

Isso evita o problema de os providers `kubernetes`/`helm` tentarem se
autenticar em um cluster que ainda não existe no mesmo plano.

## O que mudou em relação à Fase 2

- **Backend remoto**: `terraform.tfstate` agora vive em S3 (`use_lockfile`
  para lock nativo, sem precisar de tabela DynamoDB extra).
- **Modularização**: código organizado em módulos reutilizáveis
  (`network`, `eks`, `database`, `messaging`, `ecr`, `argocd`).
- **Subnets privadas**: nodes do EKS, RDS e ElastiCache agora vivem em
  subnets privadas, com egress via NAT Gateway. Antes tudo era público.
- **Security Groups mais restritos**: bancos só aceitam conexão vindo do
  Security Group dos nodes do EKS (antes era `0.0.0.0/0` nas portas 5432/6379).
- **DynamoDB renomeado** para `ToggleMasterAnalytics`, conforme especificação.
- **SQS com Dead Letter Queue** para mensagens que falham repetidamente.
- **ECR com lifecycle policy** (mantém as últimas 15 imagens por repositório).
- **Módulo ArgoCD**: instala o Argo CD via Helm diretamente no cluster,
  preparando o terreno para o GitOps pull-based (ver `../gitops/`).

## Observação sobre acesso ao banco de dados

Como RDS/Redis agora estão em subnets privadas e `publicly_accessible = false`,
não é mais possível conectar direto da máquina local (como no
`seed-databases.sh` da Fase 2). Para popular/depurar os bancos, use um pod
temporário dentro do cluster (`kubectl run psql-client --rm -it --image
postgres:16 -- bash`) ou um `kubectl port-forward` para um pod que tenha
acesso à VPC. Essa troca foi uma decisão consciente de hardening pedida pela
Fase 3 ("se não está no código, não existe" também vale para segurança de rede).
