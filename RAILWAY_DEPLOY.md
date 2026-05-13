# Деплой Pneumatic Workflow на Railway

## Быстрый старт (через шаблон)

1. Перейдите по ссылке шаблона:
   https://railway.com/workspace/templates/9e597f7d-3e28-49a0-a9cb-2a36e3127c8b
2. Нажмите **Deploy**
3. Дождитесь сборки всех сервисов (~10-15 минут)
4. Готово — приложение доступно по URL Frontend сервиса

## Архитектура

```
┌──────────────┐     ┌──────────────┐
│   Frontend   │────▶│   Backend    │
│  (Node.js)   │     │  (Django)    │
│  port: 8000  │     │  port: 8080  │
└──────────────┘     └──────┬───────┘
                            │
                    ┌───────┼───────┐
                    │       │       │
              ┌─────▼──┐ ┌─▼────┐ ┌▼─────────┐
              │Postgres │ │Redis │ │  Celery   │
              │(plugin) │ │(plgn)│ │Worker+Beat│
              └─────────┘ └──────┘ └───────────┘
```

### Сервисы

| Сервис        | Источник               | Builder    | Порт | Назначение                     |
|---------------|------------------------|------------|------|--------------------------------|
| Backend       | `backend/Dockerfile`   | DOCKERFILE | 8080 | Django API + Gunicorn/Uvicorn  |
| Frontend      | `frontend/Dockerfile`  | DOCKERFILE | 8000 | Node.js + webpack + pm2        |
| Celery Worker | `backend/Dockerfile`   | DOCKERFILE | —    | Фоновая обработка задач        |
| Celery Beat   | `backend/Dockerfile`   | DOCKERFILE | —    | Периодические задачи (cron)    |
| Postgres      | Railway plugin         | —          | 5432 | База данных                    |
| Redis         | Railway plugin         | —          | 6379 | Кеш, сессии, брокер Celery     |

> **Примечание:** Celery Worker и Celery Beat используют тот же Docker-образ что и Backend,
> но с переопределённой командой запуска (`startCommand`). RabbitMQ не нужен —
> в качестве брокера используется Redis (db 4).

## Переменные окружения

### Backend (автоматически через шаблон)

| Переменная               | Значение                                           |
|--------------------------|-----------------------------------------------------|
| `POSTGRES_PASSWORD`      | `${{Postgres.POSTGRES_PASSWORD}}`                   |
| `CACHE_REDIS_URL`        | `redis://...@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/0` |
| `AUTH_REDIS_URL`         | `redis://...@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/1` |
| `CHANNELS_REDIS_URL`     | `redis://...@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/2` |
| `SESSION_REDIS_URL`      | `redis://...@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/3` |
| `CELERY_BROKER_URL`      | `redis://...@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/4` |
| `BACKEND_URL`            | `https://${{RAILWAY_PUBLIC_DOMAIN}}`                |
| `FRONTEND_URL`           | `https://${{frontend.RAILWAY_PUBLIC_DOMAIN}}`       |
| `ALLOWED_HOSTS`          | `${{RAILWAY_PUBLIC_DOMAIN}} ${{RAILWAY_PRIVATE_DOMAIN}} localhost` |
| `CORS_ORIGIN_WHITELIST`  | `https://${{frontend.RAILWAY_PUBLIC_DOMAIN}} https://${{RAILWAY_PUBLIC_DOMAIN}}` |

### Frontend (автоматически через шаблон)

| Переменная            | Значение                                     |
|-----------------------|----------------------------------------------|
| `BACKEND_URL`         | `https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}`  |
| `BACKEND_PRIVATE_URL` | `https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}` |
| `WSS_URL`             | `wss://${{Backend.RAILWAY_PUBLIC_DOMAIN}}`    |
| `FRONTEND_URL`        | `https://${{RAILWAY_PUBLIC_DOMAIN}}`          |
| `PORT`                | `8000`                                        |

> **Важно:** `BACKEND_PRIVATE_URL` должен использовать **публичный домен** Backend,
> а не `backend.railway.internal`. Railway private networking использует IPv6,
> который не поддерживается Node.js `request` модулем — запросы падают с `ECONNREFUSED`.

### Celery Worker / Celery Beat

Наследуют те же переменные БД и Redis что и Backend.
Не имеют публичного домена (внутренние воркеры).

| Переменная          | Значение                                           |
|---------------------|-----------------------------------------------------|
| `CELERY_BROKER_URL` | `redis://...@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/4` |
| Все `POSTGRES_*`    | Те же что у Backend                                 |
| Все `*_REDIS_URL`   | Те же что у Backend                                 |

## Feature-флаги (Frontend Dockerfile)

Флаги задаются как `ENV` в `frontend/Dockerfile` **до** `RUN npm run build-client:prod`,
так как webpack `DefinePlugin` подставляет `process.env.*` в клиентский JS при сборке.

| Флаг          | По умолчанию | Описание                    |
|---------------|-------------|-----------------------------|
| `CAPTCHA`     | `no`        | Google reCAPTCHA на signup   |
| `SIGNUP`      | `yes`       | Разрешить регистрацию        |
| `BILLING`     | `no`        | Модуль биллинга              |
| `GOOGLE_AUTH` | `no`        | OAuth через Google           |
| `MS_AUTH`     | `no`        | OAuth через Microsoft        |
| `SSO_AUTH`    | `no`        | SSO авторизация              |
| `AI`          | `no`        | AI-функции                   |
| `ANALYTICS`   | `no`        | Аналитика                    |
| `PUSH`        | `no`        | Push-уведомления             |
| `STORAGE`     | `no`        | Файловое хранилище           |

> **Внимание:** Если включить `CAPTCHA=yes`, необходимо также задать
> `RECAPTCHA_SITE_KEY` и `RECAPTCHA_SECRET` — иначе страница регистрации упадёт
> с ошибкой «Missing required parameters: sitekey».

## Автодеплой

Шаблон настроен на автодеплой из GitHub:
- **Репозиторий:** `reaLm74/pneumaticworkflow`
- **Ветка:** `master`
- При каждом `git push` в `master` Railway автоматически пересобирает все сервисы

## Известные особенности

### Private Networking не работает с Node.js

Railway private networking (`*.railway.internal`) использует IPv6.
Node.js модуль `request` не поддерживает IPv6 DNS → `ECONNREFUSED`.

**Решение:** `BACKEND_PRIVATE_URL` должен указывать на **публичный** домен Backend:
```
https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}
```

### Порядок ENV в Frontend Dockerfile

`ENV` с feature-флагами (`CAPTCHA`, `SIGNUP` и др.) **обязательно** должен стоять
**до** `RUN npm run build-client:prod`. Webpack `DefinePlugin` подставляет
`process.env.*` в клиентский бандл при сборке. Если флаг не определён в момент
сборки, он будет `undefined` — и проверка `process.env.CAPTCHA !== 'no'`
вернёт `true`, включив reCAPTCHA без ключа.

```dockerfile
# ✅ Правильно — ENV ДО сборки
ENV CAPTCHA=no ...
RUN npm run build-client:prod

# ❌ Неправильно — ENV ПОСЛЕ сборки (не попадёт в клиентский бандл)
RUN npm run build-client:prod
ENV CAPTCHA=no ...
```

## Файлы конфигурации

| Файл                    | Назначение                                    |
|-------------------------|-----------------------------------------------|
| `railway.json`          | Шаблон: сервисы, переменные, плагины          |
| `backend/Dockerfile`    | Сборка и запуск Django + Gunicorn/Uvicorn     |
| `frontend/Dockerfile`   | Сборка webpack + запуск Node.js через pm2     |
| `frontend/pm2.json`     | Конфигурация pm2 для Frontend                 |
| `frontend/.env`         | Локальная разработка (не в git)               |
