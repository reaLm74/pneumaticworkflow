FROM python:3.7.11-bullseye

LABEL org.opencontainers.image.title="Pneumatic API" \
      org.opencontainers.image.source="https://github.com/pneumaticapp/pneumaticworkflow/backend" \
      org.opencontainers.image.url="https://www.pneumatic.app" \
      org.opencontainers.image.authors="support@pneumatic.app" \
      org.opencontainers.image.vendor="Pneumatic Software Inc." \
      org.opencontainers.image.documentation="https://github.com/pneumaticapp/pneumaticworkflow/wiki" \
      org.opencontainers.image.licenses="Apache-2.0"

# Install Internationalization requirements
RUN apt-get update && \
    apt-get -y install gettext postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# ===== Default environment (override via Railway Dashboard) =====

# Django core
ENV PYTHONUNBUFFERED=1 \
    ENVIRONMENT=Production \
    DJANGO_SETTINGS_MODULE=src.settings \
    DJANGO_SECRET_KEY=railway-demo-secret-key-change-in-production \
    DJANGO_DEBUG=no \
    LANGUAGE_CODE=en \
    RELEASE=1.0.0 \
    ADMIN_PATH=admin \
    SIGNUP=yes

# Postgres (override with Railway-provided values)
ENV POSTGRES_HOST=postgres.railway.internal \
    POSTGRES_PORT=5432 \
    POSTGRES_DB=postgres \
    POSTGRES_USER=postgres \
    POSTGRES_PASSWORD=password \
    POSTGRES_REPLICA_HOST=postgres.railway.internal \
    POSTGRES_REPLICA_PORT=5432 \
    POSTGRES_REPLICA_DB=postgres \
    POSTGRES_REPLICA_USER=postgres \
    POSTGRES_REPLICA_PASSWORD=password

# Redis (override with Railway-provided values)
ENV CACHE_REDIS_URL=redis://redis.railway.internal:6379/0 \
    AUTH_REDIS_URL=redis://redis.railway.internal:6379/1 \
    CHANNELS_REDIS_URL=redis://redis.railway.internal:6379/2 \
    SESSION_REDIS_URL=redis://redis.railway.internal:6379/3 \
    CELERY_BROKER_URL=redis://redis.railway.internal:6379/4

# Feature flags (all disabled by default)
ENV BILLING=no \
    ANALYTICS=no \
    CAPTCHA=no \
    EMAIL=no \
    PUSH=no \
    STORAGE=no \
    AI=no \
    GOOGLE_AUTH=no \
    MS_AUTH=no \
    SSO_AUTH=no \
    VERIFICATION_CHECK=no \
    ENABLE_LOGGING=no

# CORS
ENV CORS_ALLOW_CREDENTIALS=yes \
    CORS_ORIGIN_ALLOW_ALL=yes

# URLs (override after generating Railway domains)
ENV FRONTEND_URL=http://localhost:3000 \
    FORMS_URL=http://localhost:3000 \
    BACKEND_URL=http://localhost:8000 \
    ALLOWED_HOSTS=* \
    CORS_ORIGIN_WHITELIST=http://localhost:3000

# ===== Build =====

RUN pip install poetry==1.5.1

COPY ./pyproject.toml ./poetry.lock /tmp/

WORKDIR /pneumatic_backend
RUN poetry config virtualenvs.create false && \
    poetry install --without dev --no-root --no-interaction --directory /tmp

COPY . .

CMD bash -c "\
  python manage.py migrate && \
  python manage.py collectstatic --no-input || true && \
  python manage.py init_periodic_tasks || true && \
  python manage.py compilemessages || true && \
  exec gunicorn src.asgi:application \
    --workers 1 \
    -k uvicorn.workers.UvicornWorker \
    --worker-tmp-dir /dev/shm \
    --bind 0.0.0.0:\${PORT:-8000} \
    --timeout 200 \
    --error-logfile - \
    --access-logfile -"
