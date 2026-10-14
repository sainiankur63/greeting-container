# syntax=docker/dockerfile:1
FROM python:3.12-slim-bookworm

LABEL org.opencontainers.image.title="greeting-container" \
      org.opencontainers.image.description="DWP DevOps interview sample app" \
      org.opencontainers.image.source="https://github.com/<your-github-username>/greeting-container"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=8080

WORKDIR /app

# Create non-root user first (no login shell, no home bloat)
RUN groupadd -r appuser && useradd -r -g appuser appuser

# 1. Dependencies first for max layer caching
COPY app/requirements.txt ./app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r app/requirements.txt

# 2. App code only
COPY app/ ./app/
RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

# No curl in slim - use python stdlib so we don't add packages just for probe
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request,os; urllib.request.urlopen(f\"http://127.0.0.1:{os.environ.get('PORT','8080')}/healthz\")" || exit 1

# exec form + exec sh so $PORT is respected and SIGTERM reaches gunicorn
CMD ["sh", "-c", "exec gunicorn --chdir app --bind 0.0.0.0:${PORT:-8080} --workers 2 app:app"]