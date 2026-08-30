# Infraestrutura como Código (Terraform) — ToggleMaster — Fase 3

Este diretório provisiona toda a infraestrutura AWS do ToggleMaster de forma modular,
com state remoto (obrigatório na Fase 3). Ele substitui os arquivos `.tf` "flat" da
Fase 2 por uma estrutura de módulos reutilizáveis em `modules/`.

## Estrutura

```
terraform/
├── bootstrap/          # roda 1x: cria o bucket S3 para o state remoto
├── modules/
│   ├── network/         # VPC, subnets públicas + privadas, IGW, route tables, SGs
│   ├── eks/              # Cluster EKS + Node Group (LabRole via data source)
│   ├── rds/              # N instâncias PostgreSQL
│   ├── redis/            # Cluster ElastiCache (Redis)
│   ├── dynamodb/         # Tabela ToggleMasterAnalytics
│   ├── sqs/               # Fila de eventos
│   └── ecr/               # 5 repositórios de imagens
├── backend.tf           # backend S3 (use_lockfile, sem DynamoDB de lock)
├── backend.hcl.example  # copie para backend.hcl com o nome do seu bucket
├── main.tf               # raiz: instancia os módulos
├── variables.tf
├── outputs.tf
└── terraform.tfvars.example
```

## Recursos provisionados

- **Rede**: 1 VPC, 2 subnets públicas + 2 subnets privadas (2 AZs), IGW, route tables e Security Groups.
- **RDS PostgreSQL**: `auth-db`, `main-db`, `targeting-db` (3 instâncias, requisito da Fase 3).
- **ElastiCache Redis**: cluster `toogle-redis`.
- **DynamoDB**: tabela `ToggleMasterAnalytics` (nome exigido no desafio).
- **SQS**: fila `toogle-events`.
- **ECR**: 5 repositórios (um por microsserviço).
- **EKS**: cluster `toogle-cluster` + Node Group, associados à `LabRole` (AWS Academy).

## Decisão de arquitetura: onde ficam RDS/Redis?

O desafio pede subnets públicas **e** privadas. Criamos as duas, mas por padrão
RDS/Redis continuam nas subnets **públicas** (`database_subnets_public = true`),
porque o fluxo de seed local da Fase 2 (`aws-infra/seed-databases.sh`, rodado da
sua máquina via Docker) depende de acesso direto ao banco. Para uma postura mais
seguraça (produção), defina `database_subnets_public = false` no `terraform.tfvars`
— os bancos migram para as subnets privadas e a porta deixa de ser exposta para
`0.0.0.0/0` (mas o seed passaria a precisar rodar de dentro do cluster, ex: via
`kubectl run` ou um Job). Essa decisão está documentada no relatório de entrega.

## Pré-requisitos

1. Terraform >= 1.10 (necessário para `use_lockfile` no backend S3).
2. AWS CLI configurado (`aws configure` ou credenciais do AWS Academy).
3. AWS Academy: mantenha `use_lab_role = true` (padrão). Conta pessoal: `use_lab_role = false`.

## Passo a passo

### 1. Criar o bucket do state remoto (uma única vez)

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="bucket_name=SEU-BUCKET-DE-STATE-UNICO"
cd ..
```

### 2. Configurar o backend

```bash
cp backend.hcl.example backend.hcl
# edite backend.hcl com o nome do bucket criado acima
```

### 3. Inicializar, planejar e aplicar

```bash
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars (db_password, lab_role_name, etc.)

terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

### 4. Ver as saídas

```bash
terraform output
```

## Variáveis principais

| Variável | Descrição | Default |
|---|---|---|
| `region` | Região AWS | `us-east-1` |
| `db_password` | Senha mestra do RDS | *(obrigatória)* |
| `use_lab_role` | AWS Academy (true) ou conta pessoal (false) | `true` |
| `lab_role_name` | Nome da LabRole | `LabRole` |
| `database_subnets_public` | RDS/Redis em subnet pública ou privada | `true` |

## Por que Terraform + módulos?

- **State management**: Terraform sabe exatamente o que existe.
- **Idempotência**: `apply` repetido não duplica recursos.
- **Reuso**: cada módulo é independente e testável isoladamente.
- **Limpeza fácil**: `terraform destroy` remove tudo (importante em ambiente AWS Academy com tempo de sessão limitado).
