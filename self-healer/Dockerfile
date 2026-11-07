# Self-healer (Fase 4). Build a partir da raiz do repo:
#   docker build -f self-healer/Dockerfile -t self-healer .
FROM python:3.11-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

COPY self-healer/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt \
 # wheels antigos embutidos na imagem base (o Trivy acusa CVE neles - licao da Fase 3)
 && rm -rf /usr/local/lib/python3.11/ensurepip/_bundled

COPY self-healer/app.py .

RUN useradd --uid 10001 --no-create-home appuser
USER 10001

EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "4", "--access-logfile", "-", "app:app"]
