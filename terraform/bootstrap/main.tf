# Bootstrap: cria o bucket S3 usado como backend remoto do estado principal.
# Este projeto usa estado LOCAL de propósito (é a única peça que precisa
# existir antes do backend remoto poder ser configurado - "ovo e a galinha").
#
# Uso:
#   cd terraform/bootstrap
#   terraform init
#   terraform apply -var bucket_name=SEU-BUCKET-UNICO-GLOBALMENTE
#
# Depois, em terraform/providers.tf, aponte o backend "s3" para o mesmo bucket.

terraform {
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

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "Nome único (globalmente) do bucket S3 para o tfstate"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = var.bucket_name

  tags = {
    Project = "ToogleMaster"
    Purpose = "terraform-remote-state"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  value = aws_s3_bucket.tfstate.bucket
}
