# Configurar o GitHub Actions (Secrets) — Fase 3

Os 5 workflows (`.github/workflows/*.yml`) precisam destes **Secrets** do
repositório (Settings → Secrets and variables → Actions → New repository
secret):

| Secret | De onde vem | Obrigatório |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Credenciais AWS (Academy ou pessoal) | sim |
| `AWS_SECRET_ACCESS_KEY` | Credenciais AWS | sim |
| `AWS_SESSION_TOKEN` | **Só AWS Academy** — as credenciais são temporárias e incluem um session token | apenas AWS Academy |
| `AWS_REGION` | Região usada (ex: `us-east-1`) | sim |
| `AWS_ACCOUNT_ID` | ID da conta AWS (`aws sts get-caller-identity --query Account --output text`) | sim |

⚠️ **AWS Academy**: as credenciais expiram em poucas horas. Antes de gravar o
vídeo de demonstração ou rodar o pipeline, atualize os 3 secrets AWS com as
credenciais atuais do Lab (AWS Details → AWS CLI: mostrar credenciais).

## Permissões do workflow

O job `update-gitops` faz `git push` de volta no repositório (para atualizar
a tag da imagem em `gitops/<serviço>/deployment.yaml`). Isso exige permissão
de escrita do `GITHUB_TOKEN` padrão:

Settings → Actions → General → Workflow permissions → **Read and write
permissions**.

(Já declaramos `permissions: contents: write` no job especificamente, mas o
repositório também precisa permitir isso globalmente.)

## Testando o "pipeline falhando" (para o vídeo)

Para gravar a parte do vídeo em que o pipeline **falha no passo de
segurança**, uma forma fácil e reversível:

- **Go** (auth-service/evaluation-service): adicione uma dependência
  vulnerável conhecida ao `go.mod` (ex: uma versão antiga de alguma lib com
  CVE documentado) ou introduza um padrão que o `gosec` sinalize como HIGH
  (ex: `fmt.Sprintf` montando uma query SQL em vez de usar parâmetros).
- **Python** (flag/targeting/analytics-service): adicione ao
  `requirements.txt` uma versão antiga e vulnerável de uma lib (ex:
  `Flask==0.12` tem CVEs conhecidos) — o Trivy (SCA) vai pegar isso. Para o
  `bandit` (SAST) sinalizar, um `eval()` com entrada do usuário ou uma
  `subprocess` com `shell=True` costumam disparar HIGH.

Abra um Pull Request com essa mudança → mostre o job `sca` ou `sast`
falhando (vermelho) → reverta a mudança (novo commit ou fecha o PR) → mostre
o pipeline passando (verde).
