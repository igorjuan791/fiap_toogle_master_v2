############################################
# Bootstrap: cria o bucket S3 que vai guardar o terraform.tfstate do projeto
# principal. Roda com state LOCAL mesmo (problema do ovo e da galinha: o
# backend remoto nao pode se autocriar). Aplique isso UMA VEZ, antes do
# `terraform init` do modulo raiz.
#
# Uso:
#   cd terraform/bootstrap
#   terraform init
#   terraform apply -var="bucket_name=SEU-BUCKET-DE-STATE-UNICO"
############################################

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "bucket_name" {
  description = "Nome (globalmente unico) do bucket S3 para o state"
  type        = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

resource "aws_s3_bucket" "state" {
  bucket = var.bucket_name

  # Em AWS Academy a conta expira e o bucket some junto; force_destroy
  # evita erro de "bucket not empty" ao limpar o ambiente no fim do curso.
  force_destroy = true

  tags = {
    Project = "ToggleMaster"
    Purpose = "terraform-remote-state"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  value = aws_s3_bucket.state.id
}
