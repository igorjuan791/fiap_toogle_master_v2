# self-healer

Automacao de resposta a incidentes da Fase 4. Recebe o webhook do Grafana Alerting e faz
`rollout restart` do deployment indicado no label `deployment` do alerta.

- Endpoint: `POST /webhook` (payload padrao do Grafana), `GET /health`
- Permissoes: ServiceAccount `self-healer` com Role `get/patch deployments` so no namespace `toogle-master`
- Protecoes: allowlist de deployments e cooldown de 5 min por deployment
- Notifica o Discord quando age (env `DISCORD_WEBHOOK_URL`)

Teste manual (com port-forward na porta 8080):

    curl -X POST localhost:8080/webhook -H 'Content-Type: application/json' \
      -d '{"alerts":[{"status":"firing","labels":{"alertname":"teste","deployment":"evaluation-service","namespace":"toogle-master"}}]}'
