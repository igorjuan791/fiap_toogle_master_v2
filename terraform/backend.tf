# Backend remoto (Requisito Fase 3: "o terraform.tfstate nao pode ficar local").
#
# O bloco backend nao aceita variaveis, entao o bucket/region sao passados na
# hora do `terraform init` via arquivo de config (ver backend.hcl.example) ou
# -backend-config. Isso evita hardcodar o nome do bucket (que e unico por conta)
# direto no codigo versionado.
#
# `use_lockfile = true` usa o locking nativo do S3 (Terraform >= 1.10), sem
# precisar de uma tabela DynamoDB extra so para lock.
terraform {
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
