# GitOps — ToggleMaster — Fase 3

Esta pasta é o "repositório de GitOps" exigido pelo desafio (aqui, uma pasta
dentro do monorepo — permitido pelo enunciado). Contém **apenas manifestos
Kubernetes**, sem lógica de build. O **ArgoCD** monitora esta pasta e
sincroniza o cluster EKS automaticamente sempre que algo muda aqui.

## Estrutura

```
gitops/
├── namespace.yaml              # namespace toogle-master
├── ingress.yaml                 # roteamento externo (nginx ingress)
├── auth-service/
│   ├── deployment.yaml          # <- tag da imagem atualizada pelo CI
│   ├── service.yaml
│   └── configmap.yaml
├── flag-service/          (mesma estrutura)
├── targeting-service/     (mesma estrutura)
├── evaluation-service/    (+ hpa.yaml)
├── analytics-service/     (+ hpa.yaml)
├── secrets/
│   ├── *.env.example        # modelos (sem valores reais)
│   └── bootstrap-secrets.sh # cria os Secrets no cluster (fora do ArgoCD)
└── argocd/
    ├── install.sh                       # instala o ArgoCD + as Applications
    └── applications/*.yaml   # 1 Application por microsserviço + 1 compartilhada
```

## Por que os Secrets não ficam aqui dentro do fluxo do ArgoCD?

Este repositório é versionado (e pode ser público). Credenciais de banco,
chaves de API etc. **nunca** devem ir para o Git em texto plano. Por isso:

- Os `Deployment`s aqui **referenciam** Secrets pelo nome (`secretKeyRef`),
  mas não os definem.
- Os Secrets de verdade são criados **uma única vez**, fora do ArgoCD, com
  `gitops/secrets/bootstrap-secrets.sh` (veja o script para instruções).
- Isso é uma prática comum em GitOps real (a alternativa "completa" seria
  Sealed Secrets / External Secrets Operator, fora do escopo deste desafio).

## Fluxo completo (do commit ao cluster)

1. Você altera código em `services/<algum-serviço>/`.
2. Push/PR na `main` dispara o workflow daquele serviço
   (`.github/workflows/<serviço>.yml`, veja a raiz do repo).
3. O pipeline builda, testa, faz lint, roda SCA/SAST (Trivy/gosec/bandit) —
   se achar vulnerabilidade CRÍTICA, o pipeline **falha e para aqui**.
4. Se tudo passar, builda a imagem Docker, escaneia a imagem com Trivy, e
   envia para o ECR com a tag `v1.0.0-<hash-do-commit>`.
5. O job `update-gitops` edita `gitops/<serviço>/deployment.yaml`, trocando
   a linha `image:` para a nova tag, e faz commit/push direto na `main`.
6. O **ArgoCD**, que monitora este repositório, detecta a mudança e
   sincroniza automaticamente o novo `Deployment` no cluster EKS
   (`prune: true`, `selfHeal: true` — self-healing caso algo seja alterado
   manualmente no cluster).

## Instalar o ArgoCD e as Applications

```bash
# 1) Configure o kubectl para o cluster criado pelo Terraform
aws eks update-kubeconfig --region us-east-1 --name toogle-cluster

# 2) Rode o instalador (Helm) — detecta a URL do seu repo automaticamente
cd gitops/argocd
./install.sh
# ou, se preferir passar explicitamente:
./install.sh https://github.com/SEU_USUARIO/SEU_REPO.git
```

Isso instala o ArgoCD no namespace `argocd` e aplica 6 `Application`s: uma
para os manifestos compartilhados (`namespace.yaml`, `ingress.yaml`) e uma
para cada um dos 5 microsserviços, cada uma apontando para sua respectiva
subpasta em `gitops/`.

## Acessar a UI do ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# abra https://localhost:8080
# usuário: admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

Na UI você deve ver os 5 microsserviços + o app compartilhado, todos
`Synced`/`Healthy` — essa tela é o que o roteiro do vídeo (`docs/DEMO_SCRIPT.md`)
pede para gravar como evidência do ArgoCD gerenciando os 5 microsserviços.

## Bootstrap de add-ons de cluster (fora do GitOps)

`metrics-server` e o controller do `ingress-nginx` são add-ons de
infraestrutura do cluster, não da aplicação — instale-os uma vez,
manualmente, antes do ArgoCD entrar em cena:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
kubectl apply -f ../k8s/metrics-server.yaml
```

(O antigo caminho manual descrito em `k8s/` — `kubectl apply -k` / Helm chart
— continua funcionando e é útil para debug local, mas na Fase 3 o caminho
"oficial" de entrega para o EKS é este, via GitOps + ArgoCD.)
