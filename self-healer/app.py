"""Self-healer do ToggleMaster (Fase 4).

Recebe o webhook do Grafana Alerting e, para cada alerta em estado "firing",
executa o equivalente a `kubectl rollout restart deployment/<nome> -n <namespace>`
usando a API do Kubernetes (ServiceAccount com RBAC minimo: get/patch em deployments).

Protecoes:
  - allowlist: so reinicia os 5 microsservicos do ToggleMaster;
  - cooldown: no maximo 1 restart por deployment a cada COOLDOWN_SECONDS (evita "restart storm"
    enquanto o alerta continua firing durante a recuperacao);
  - alertas "resolved" so geram log/notificacao, nunca acao.
"""
import logging
import os
import threading
import time
from datetime import datetime, timezone

import requests
from flask import Flask, jsonify, request
from kubernetes import client, config

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [self-healer] %(message)s",
)
log = logging.getLogger("self-healer")

ALLOWED_DEPLOYMENTS = set(
    os.getenv(
        "ALLOWED_DEPLOYMENTS",
        "auth-service,flag-service,targeting-service,evaluation-service,analytics-service",
    ).split(",")
)
DEFAULT_NAMESPACE = os.getenv("DEFAULT_NAMESPACE", "toogle-master")
COOLDOWN_SECONDS = int(os.getenv("COOLDOWN_SECONDS", "300"))
DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL", "")

_last_restart = {}
_lock = threading.Lock()

try:
    config.load_incluster_config()
except config.ConfigException:
    config.load_kube_config()  # execucao local, para testes
apps_api = client.AppsV1Api()

app = Flask(__name__)


def notify_discord(text):
    if not DISCORD_WEBHOOK_URL:
        return
    try:
        requests.post(DISCORD_WEBHOOK_URL, json={"content": text}, timeout=5)
    except requests.RequestException as exc:
        log.warning("falha ao notificar o Discord: %s", exc)


def rollout_restart(deployment, namespace):
    now = datetime.now(timezone.utc).isoformat()
    body = {
        "spec": {
            "template": {
                "metadata": {"annotations": {"kubectl.kubernetes.io/restartedAt": now}}
            }
        }
    }
    apps_api.patch_namespaced_deployment(name=deployment, namespace=namespace, body=body)
    return now


def handle_alert(alert):
    status = alert.get("status", "")
    labels = alert.get("labels", {})
    name = labels.get("alertname", "?")
    deployment = labels.get("deployment", "")
    namespace = labels.get("namespace", DEFAULT_NAMESPACE)

    if status != "firing":
        log.info("alerta '%s' com status '%s' para %s: nenhuma acao", name, status, deployment)
        return {"deployment": deployment, "action": "none", "reason": f"status={status}"}

    if deployment not in ALLOWED_DEPLOYMENTS:
        log.warning("deployment '%s' fora da allowlist, ignorando", deployment)
        return {"deployment": deployment, "action": "none", "reason": "fora da allowlist"}

    with _lock:
        elapsed = time.time() - _last_restart.get(deployment, 0)
        if elapsed < COOLDOWN_SECONDS:
            log.info(
                "cooldown ativo para %s (%.0fs desde o ultimo restart), ignorando",
                deployment, elapsed,
            )
            return {"deployment": deployment, "action": "none", "reason": "cooldown"}
        _last_restart[deployment] = time.time()

    log.info(
        "SELF-HEALING: alerta '%s' firing -> executando rollout restart deployment/%s -n %s",
        name, deployment, namespace,
    )
    try:
        ts = rollout_restart(deployment, namespace)
    except client.ApiException as exc:
        log.error("falha no rollout restart de %s: %s %s", deployment, exc.status, exc.reason)
        with _lock:
            _last_restart.pop(deployment, None)
        notify_discord(f"❌ Self-healing FALHOU para `deployment/{deployment}`: {exc.reason}")
        return {"deployment": deployment, "action": "error", "reason": str(exc.reason)}

    log.info("SELF-HEALING: rollout restart de %s concluido (restartedAt=%s)", deployment, ts)
    notify_discord(
        f"🤖 **Self-healing executado**: `kubectl rollout restart deployment/{deployment} -n {namespace}`\n"
        f"Motivo: alerta **{name}** em estado firing. Horário: {ts}"
    )
    return {"deployment": deployment, "action": "rollout-restart", "restartedAt": ts}


@app.post("/webhook")
def webhook():
    payload = request.get_json(silent=True) or {}
    alerts = payload.get("alerts", [])
    log.info("webhook recebido: %d alerta(s), status geral '%s'", len(alerts), payload.get("status"))
    results = [handle_alert(a) for a in alerts]
    return jsonify({"results": results}), 200


@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200
