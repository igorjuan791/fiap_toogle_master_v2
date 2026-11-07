# Guia de aplicação — Fase 4 (pacote fase4-codigo.zip)

Tudo aqui roda no **WSL (Ubuntu)**, dentro de `~/fiap_toogle_master_v2`. Rode um bloco por vez e cole a saída na conversa se algo der errado.

## O que vem no pacote

| Caminho | O que é | Frente |
|---|---|---|
| `gitops/argocd/applications/observability-*.yaml` | 4 Applications do ArgoCD (Prometheus/Grafana, Loki, OTel Collector, config) | Igor |
| `gitops/observability/kube-prometheus-stack/values.yaml` | Prometheus + Grafana + node-exporter + kube-state-metrics | Igor |
| `gitops/observability/loki/values.yaml` | Loki SingleBinary | Igor |
| `gitops/observability/otel-collector/values.yaml` | OTel Collector (DaemonSet) com rotas para Prometheus, Loki e New Relic | Igor |
| `gitops/observability/config/grafana-alerting.yaml` | Alerta 5xx > 5% + contact points PagerDuty, Discord e self-healer | Igor / Robson |
| `gitops/observability/config/grafana-dashboard.yaml` | Dashboard "ToggleMaster - Saúde do Ecossistema" | Robson (base pronta) |
| `gitops/observability/config/self-healer.yaml` | Deployment, Service, ServiceAccount e RBAC mínimo do self-healer | Igor |
| `gitops/observability/config/load-generator.yaml` | Gerador de carga contínuo | Igor |
| `self-healer/` + `.github/workflows/self-healer.yml` | Código do self-healer + pipeline (mesma esteira DevSecOps) | Igor |
| `gitops/secrets/observability.env.example` | Modelo dos segredos novos | Igor |
| `services/evaluation-service/*` + `gitops/evaluation-service/deployment.yaml` | Instrumentação OTel + chaos endpoint (compila e passa no gosec) | Marcela |
| `docs/RUNBOOK.md` | Runbook do alerta (linkado na notificação) | todos |

---

## Parte A — Igor (tarefas 1, 2, 3 e 9)

### A1. Colocar os arquivos no repositório
Baixe o `fase4-codigo.zip` do chat para a pasta Downloads do Windows.
```bash
cd ~/fiap_toogle_master_v2
git checkout main && git pull origin main
git checkout -b fase4/01-observabilidade
sudo apt install -y unzip   # se ainda não tiver
unzip -o /mnt/c/Users/Igor/Downloads/fase4-codigo.zip -d .
git status
```
> O `services/evaluation-service` é um submódulo: os arquivos dele ficam lá, mas são commitados na Parte B (pela Marcela, ou por você seguindo a Parte B).

### A2. Garantir que o arquivo de segredos não vai para o git
```bash
cp gitops/secrets/observability.env.example gitops/secrets/observability.env
git check-ignore gitops/secrets/observability.env && echo "OK, ignorado" || echo "ATENCAO: adicione ao .gitignore"
```
Se aparecer ATENÇÃO: `echo "gitops/secrets/observability.env" >> .gitignore`.
Depois preencha o `observability.env` (com `nano gitops/secrets/observability.env`) com a license key do New Relic, a integration key do PagerDuty, o webhook do Discord e uma senha para o Grafana.

### A3. Subir o ambiente e aumentar o cluster para 3 nós
Start Lab no Academy, atualize `~/.aws/credentials` e:
```bash
aws sts get-caller-identity
cd terraform
grep -nE 'eks_(desired|min|max)_size|eks_instance_types' terraform.tfvars variables.tf
```
No `terraform.tfvars`, deixe `eks_desired_size = 3` e `eks_max_size = 4` (se a variável `eks_max_size` não estiver no tfvars, adicione). Se o Academy permitir, troque `eks_instance_types` para `["t3.large"]`.

Repositório ECR do self-healer:
```bash
grep -rn -iE 'repositor|ecr' terraform.tfvars variables.tf main.tf modules/ecr/*.tf | head -20
```
Onde estiver a lista com os 5 serviços, adicione `"self-healer"`. Depois:
```bash
terraform init -backend-config=backend.hcl
terraform plan    # deve mudar só o node group e criar o ECR self-healer
terraform apply
terraform output   # anote o nome do cluster
aws eks update-kubeconfig --name <nome-do-cluster> --region us-east-1
kubectl get nodes -w   # Ctrl+C quando os 3 estiverem Ready
cd ..
```

### A4. Criar os Secrets no cluster (fora do git)
```bash
set -a; source gitops/secrets/observability.env; set +a
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl -n observability create secret generic newrelic-license \
  --from-literal=NEW_RELIC_LICENSE_KEY="$NEW_RELIC_LICENSE_KEY" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n observability create secret generic grafana-alerting-secrets \
  --from-literal=PAGERDUTY_KEY="$PAGERDUTY_KEY" \
  --from-literal=DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK_URL" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n observability create secret generic grafana-admin \
  --from-literal=admin-user="$GRAFANA_ADMIN_USER" \
  --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n observability get secrets
```

### A5. Ajustar o gerador de carga com flags reais
```bash
grep -ohE 'flag_name=[A-Za-z0-9_-]+|"name": *"[A-Za-z0-9_-]+"' smoke-test.sh aws-infra/seed-databases.sh 2>/dev/null | sort -u
```
Troque os dois primeiros nomes da variável `FLAGS` em `gitops/observability/config/load-generator.yaml` pelas flags que existem no banco (mantenha os dois `flag-inexistente-*`: eles forçam chamadas ao flag/targeting e geram traces distribuídos).

### A6. Commit, PR e merge
```bash
git add gitops/argocd/applications gitops/observability gitops/secrets/observability.env.example \
        self-healer .github/workflows/self-healer.yml docs terraform .gitignore
git status   # confira que NENHUM .env real aparece
git commit -m "feat(fase4): stack de observabilidade, OTel Collector, alertas e self-healer via GitOps"
git push -u origin fase4/01-observabilidade
gh pr create --fill --base main
```
Espere o pipeline do self-healer ficar verde no PR e faça o merge (`gh pr merge --merge`). No push para a main o pipeline publica a imagem no ECR e atualiza a tag em `gitops/observability/config/self-healer.yaml`.

### A7. Registrar os Applications no ArgoCD
Use a mesma URL de repositório dos Applications atuais:
```bash
git checkout main && git pull origin main
REPO=$(kubectl -n argocd get application auth-service -o jsonpath='{.spec.source.repoURL}'); echo $REPO
for app in kube-prometheus-stack loki otel-collector config; do
  sed "s#__REPO_URL__#$REPO#" gitops/argocd/applications/observability-$app.yaml | kubectl apply -f -
done
kubectl -n argocd get applications
```
Espere uns 3 a 5 minutos. **Pronto quando**: os 10 Applications aparecem `Synced` / `Healthy`.
```bash
kubectl -n observability get pods -o wide
```
> Se o `observability-config` ficar `Degraded` só por causa do `self-healer` com `ImagePullBackOff`, é porque o pipeline ainda não publicou a imagem — confira `gh run list --workflow=self-healer.yml`.

> Os charts estão com `targetRevision: "*"` (última versão). Depois do primeiro sync que der certo, anote a versão que o ArgoCD mostra em cada Application e fixe no YAML — evita surpresa no dia da gravação.

### A8. Validar (e tirar os prints)
Grafana:
```bash
kubectl -n observability port-forward svc/kps-grafana 3000:80
```
Abra http://localhost:3000 (usuário e senha do `observability.env`).
- **Connections > Data sources**: Prometheus e Loki com "Test" verde.
- **Explore > Loki**: `{k8s_namespace_name="toogle-master"}` deve trazer logs dos 5 serviços.
- **Dashboards > ToggleMaster**: o dashboard "Saúde do Ecossistema" aparece sozinho (veio do Git).
- **Alerting > Alert rules**: a regra do evaluation-service aparece `Normal`.
- **Alerting > Contact points > togglemaster-oncall > Test**: deve chegar um incidente de teste no PagerDuty e uma mensagem no Discord.

Self-healer (simulando o webhook do Grafana):
```bash
kubectl -n observability port-forward svc/self-healer 8080:8080 &
curl -s -X POST localhost:8080/webhook -H 'Content-Type: application/json' \
  -d '{"alerts":[{"status":"firing","labels":{"alertname":"teste-manual","deployment":"evaluation-service","namespace":"toogle-master"}}]}'
kubectl -n observability logs deploy/self-healer --tail=20
kubectl -n toogle-master get pods -l app=evaluation-service -w
```
**Pronto quando**: o log mostra `SELF-HEALING: rollout restart ... concluido`, os pods do evaluation-service são recriados e chega a mensagem 🤖 no Discord. 📸 Print obrigatório #4.

> As métricas de taxa de requisição, a % de 5xx e os traces só aparecem depois da Parte B (instrumentação).

---

## Parte B — Marcela (tarefas 5 e 10): evaluation-service

Os arquivos já estão na pasta `services/evaluation-service` depois do unzip (ou a Marcela copia do pacote).
```bash
cd ~/fiap_toogle_master_v2/services/evaluation-service
git checkout -b fase4/05-instrumentacao-go
go build ./... && go vet ./...
grep "^go " go.mod   # tem que ser "go 1.26.0": a versão corrigida do golang.org/x/net exige Go 1.26
git add . && git commit -m "feat(fase4): instrumentacao OpenTelemetry, propagacao de trace na SQS e chaos endpoint"
git push -u origin fase4/05-instrumentacao-go
gh pr create --fill --base main
```
Depois do merge no repositório do serviço, atualize o ponteiro e o deployment no repositório pai:
```bash
cd ~/fiap_toogle_master_v2
git checkout -b fase4/05-ponteiro-evaluation
cd services/evaluation-service && git checkout main && git pull && cd ../..
git add services/evaluation-service gitops/evaluation-service/deployment.yaml
git commit -m "chore(fase4): evaluation-service instrumentado + env OTEL e CHAOS_ENABLED"
git push -u origin fase4/05-ponteiro-evaluation && gh pr create --fill --base main
```
> Lição da Fase 3: se o pipeline do evaluation-service não disparar só com a mudança de ponteiro, adicione a linha `- "services/evaluation-service"` (sem `/**`) nos `paths:` de `.github/workflows/evaluation-service.yml`.

O que mudou no código:
- `telemetry.go` (novo): SDK OTel, traces e métricas via OTLP/gRPC para o Collector, configurado por variáveis `OTEL_*`.
- `main.go`: servidor envolvido com `otelhttp.NewHandler` (span por requisição + métrica `http.server.request.duration`), cliente HTTP com `otelhttp.NewTransport` (propaga o `traceparent` para flag/targeting) e encerramento gracioso.
- `evaluator.go` / `handlers.go`: o `ctx` da requisição é repassado até as chamadas HTTP e ao Redis.
- `sqs.go`: span de producer e `traceparent` nos `MessageAttributes` da mensagem.
- `chaos.go` (novo): `POST /chaos/enable|disable` e `GET /chaos/status`, só ativos com `CHAOS_ENABLED=true`.

Nos outros 4 serviços, cada `deployment.yaml` recebe as mesmas 3 variáveis (trocando o `OTEL_SERVICE_NAME`):
```yaml
            - name: OTEL_SERVICE_NAME
              value: flag-service
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: http://otel-collector.observability.svc.cluster.local:4317
            - name: OTEL_RESOURCE_ATTRIBUTES
              value: service.namespace=toogle-master,deployment.environment=fiap-fase4
```
(As mudanças de código/Dockerfile do auth e dos 3 serviços Python vêm num próximo pacote.)

---

## Parte C — A "prova real" (ensaio do dia 13/11)

```bash
# terminal 1: acompanhar os pods
kubectl -n toogle-master get pods -l app=evaluation-service -w
# terminal 2: ligar a falha em um pod (~50% das respostas viram 500, bem acima dos 5%)
kubectl -n toogle-master port-forward deploy/evaluation-service 8004:8004 &
curl -s -X POST localhost:8004/chaos/enable
```
Sequência esperada (≈2 a 3 min): painel de 5xx sobe → alerta `Pending` → `Firing` → incidente no PagerDuty + mensagem no Discord → self-healer faz o restart (mensagem 🤖) → pods novos sem chaos → erro volta a 0 → alerta `Normal` → incidente resolvido sozinho e mensagem ✅ no Discord.
