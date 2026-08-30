# Relatório de Entrega — Tech Challenge Fase 3 — ToggleMaster

> Preencha e exporte como PDF (ou entregue como .txt/.md, conforme o
> enunciado permite "PDF ou .txt").

## Participantes

- Nome completo — RM / e-mail
- (adicione os demais integrantes do grupo)

## Links

- Repositório: https://github.com/igorjuan791/fiap_toogle_master_v2
- Vídeo de demonstração: `<link do YouTube/Drive/etc>`

## Resumo dos desafios encontrados e decisões tomadas

> Sugestão de tópicos a cobrir (adapte com a experiência real do grupo):

- **Backend remoto do Terraform**: optamos por S3 com `use_lockfile = true`
  (locking nativo do Terraform ≥ 1.10) em vez de uma tabela DynamoDB
  dedicada para lock, simplificando a infraestrutura de bootstrap.
- **Subnets públicas x privadas**: criamos subnets públicas e privadas na
  VPC (requisito do desafio), mas mantivemos RDS/Redis nas subnets públicas
  por padrão para não quebrar o fluxo de seed de dados via Docker local
  (herdado da Fase 2). A troca para subnets privadas é uma flag
  (`database_subnets_public = false`) documentada no `terraform/README.md`.
- **AWS Academy (LabRole)**: seguimos a Opção A do desafio — nenhuma Role ou
  Policy de IAM é criada pelo Terraform; a `LabRole` existente é importada
  via `data "aws_iam_role"` e associada ao cluster EKS e ao Node Group.
- **SAST/SCA sem custo**: usamos Trivy (SCA + scan de imagem, ambos com
  gate em vulnerabilidades CRITICAL/HIGH) e gosec/bandit (SAST, gate em
  HIGH+HIGH confidence) em vez de SonarCloud, evitando depender de uma conta
  externa paga/limitada.
- **CI reutilizável**: em vez de duplicar a mesma lógica de pipeline 5
  vezes, criamos um `workflow_call` reutilizável
  (`.github/workflows/_reusable-service-ci.yml`) chamado por um workflow fino
  por microsserviço — mesma cobertura exigida pelo desafio, com menos
  duplicação/risco de divergência.
- **GitOps no monorepo**: em vez de um repositório Git separado só para os
  manifestos, usamos uma pasta dedicada (`gitops/`) dentro do mesmo repo —
  permitido pelo enunciado ("um repositório separado **ou** uma pasta
  separada no monorepo").
- **Secrets fora do Git**: os `Deployment`s do GitOps referenciam Secrets do
  Kubernetes pelo nome, mas os valores reais são aplicados uma única vez via
  `gitops/secrets/bootstrap-secrets.sh`, fora do controle do ArgoCD — para
  não versionar credenciais em texto plano no repositório.
- *(adicione aqui qualquer problema específico que o grupo enfrentou:
  cotas do AWS Academy, tempo de sessão do Lab, versões de Kubernetes,
  etc.)*

## Estimativa de custos AWS

> Cole aqui o print da AWS Pricing Calculator ou do Cost Explorer, conforme
> pedido no enunciado ("Print da estimativa de custos da AWS").

`<inserir imagem/print aqui>`

Principais componentes de custo:
- EKS: taxa fixa do control plane (~US$0,10/hora) + EC2 dos nodes (2x
  `t3.medium`).
- RDS: 3x `db.t3.medium`.
- ElastiCache: 1x `cache.t3.medium`.
- Sem NAT Gateway (decisão de arquitetura acima) — economia relevante em um
  ambiente de estudo.
