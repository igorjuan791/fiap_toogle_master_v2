# Runbook - evaluation-service com taxa de erro 5xx acima de 5%

**Alerta**: `evaluation-service com taxa de erro 5xx acima de 5%` (Grafana Alerting, pasta ToggleMaster)
**Severidade**: critical | **Contatos**: PagerDuty (service togglemaster-evaluation) + Discord #alertas-togglemaster

## O que acontece automaticamente
1. O Grafana avalia a regra a cada 30s; com a condicao verdadeira por 1 min, o alerta vai para Firing.
2. O contact point `togglemaster-oncall` abre um incidente no PagerDuty, posta no Discord e chama o webhook do `self-healer`.
3. O `self-healer` executa `rollout restart deployment/evaluation-service -n toogle-master` (cooldown de 5 min) e avisa no Discord.
4. Com os pods novos, a taxa de erro volta ao normal, o alerta vai para Normal e o incidente e resolvido sozinho no PagerDuty.

## Se o restart nao resolver (diagnostico manual)
1. Dashboard "ToggleMaster - Saude do Ecossistema": qual servico tem erro? A latencia subiu junto?
2. Logs no Loki: `{k8s_namespace_name="toogle-master", service_name="evaluation-service"} |~ "(?i)error"`
3. Trace no New Relic (APM > evaluation-service > Errors): o erro e no proprio servico ou numa dependencia (flag/targeting/Redis/SQS)?
4. Estado dos pods: `kubectl get pods -n toogle-master -l app=evaluation-service` e `kubectl describe pod ...`
5. Dependencias: `kubectl get pods -n toogle-master`, conexao com Redis/RDS (security groups), credenciais do Academy expiradas (SQS/DynamoDB).
