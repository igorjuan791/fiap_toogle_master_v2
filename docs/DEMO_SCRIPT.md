# Roteiro do Vídeo de Demonstração (até 20 min) — Fase 3

Checklist de tudo que o enunciado pede para aparecer no vídeo, na ordem
sugerida. Marque cada item enquanto grava.

## 1. IaC — Terraform (≈ 5 min)

- [ ] Mostrar a estrutura de módulos (`terraform/modules/*`).
- [ ] `cd terraform && terraform init -backend-config=backend.hcl` — mostrar
      que o backend é o S3 (não local).
- [ ] `terraform plan` — passar pelos recursos que serão criados (VPC, EKS,
      3x RDS, Redis, DynamoDB, SQS, ECR).
- [ ] `terraform apply` — pode acelerar/cortar no vídeo, mas mostrar o
      início rodando e o resultado final (`Apply complete!`).
- [ ] Alternativa mais rápida: se a infra já estiver de pé, mostrar direto
      no Console AWS: VPC, cluster EKS, as 3 instâncias RDS.

## 2. Pipeline de CI + DevSecOps (≈ 7 min)

- [ ] Abrir a aba **Actions** do GitHub, mostrar os 5 workflows (um por
      microsserviço).
- [ ] Abrir um Pull Request introduzindo uma vulnerabilidade proposital (ver
      `docs/CI_SETUP.md` → "Testando o pipeline falhando") em **um**
      microsserviço.
- [ ] Mostrar o pipeline **falhando** no job `sca` ou `sast` — abrir o log e
      mostrar a vulnerabilidade CRÍTICA/HIGH apontada pelo Trivy/gosec/bandit.
- [ ] Reverter a vulnerabilidade (novo commit no mesmo PR).
- [ ] Mostrar o pipeline **passando** em todos os jobs (build-test, lint,
      sca, sast, docker-build-push).
- [ ] Fazer merge na `main` — mostrar o job `docker-build-push` enviando a
      imagem para o ECR com a tag `v1.0.0-<hash>` (mostrar o repositório ECR
      com a nova tag).

## 3. GitOps (≈ 3 min)

- [ ] Depois do merge, mostrar o job `update-gitops` rodando e o commit
      automático que ele fez em `gitops/<serviço>/deployment.yaml` (abrir o
      diff do commit no GitHub — a linha `image:` mudou para a nova tag).

## 4. ArgoCD (≈ 5 min)

- [ ] Abrir a UI do ArgoCD (`kubectl port-forward svc/argocd-server -n
      argocd 8080:443`).
- [ ] Mostrar os 6 Applications (5 microsserviços + compartilhado), todos
      `Synced` / `Healthy`.
- [ ] Mostrar o Application do serviço que você acabou de atualizar
      detectando a mudança (ícone "OutOfSync" → sincronizando → "Synced"
      de novo) — se possível, capturar isso acontecendo ao vivo logo após o
      passo 3.
- [ ] Abrir a árvore de recursos do Application (Deployment → ReplicaSet →
      Pods) e mostrar que o Pod novo está rodando com a imagem atualizada
      (`kubectl describe pod ... | grep Image` ou a própria UI do ArgoCD).

## Dicas

- Grave em 1 take por seção é mais fácil de editar depois do que tentar
  fazer tudo de uma vez sem cortes.
- Se o Terraform apply demorar muito (EKS leva ~10-15 min), grave o início e
  o fim separadamente e edite um corte no meio, avisando "aguardando o EKS
  provisionar".
- Tenha as credenciais AWS Academy atualizadas ANTES de gravar (elas
  expiram) — veja `docs/CI_SETUP.md`.
