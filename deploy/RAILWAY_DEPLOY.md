# 🚀 Развёртывание PneumaticWorkflow на Railway

Полная инструкция по развёртыванию проекта с нуля на [Railway](https://railway.app).  
Время: **~5 минут**.

---

## 📐 Архитектура

```
┌──────────────────────────────────────────────────────┐
│                   Railway Project                     │
│                                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────┐│
│  │ Backend  │  │ Frontend │  │ Postgres │  │ Redis ││
│  │ Django   │  │ Express  │  │    DB    │  │ Cache ││
│  │ Gunicorn │  │ PM2      │  │          │  │       ││
│  └────┬─────┘  └────┬─────┘  └──────────┘  └───────┘│
│       │              │                                │
│       └──────────────┘                                │
│     Оба подключаются к Postgres и Redis               │
└──────────────────────────────────────────────────────┘
```

---

## Шаг 1. Создание проекта

1. Откройте [railway.app](https://railway.app) → войдите через GitHub
2. **"New Project"** → **"Empty Project"**

---

## Шаг 2. Добавление баз данных

1. **"+ New"** → **"Database"** → **"Add PostgreSQL"** — подождите 30 сек
2. **"+ New"** → **"Database"** → **"Add Redis"** — подождите 30 сек

> 💡 Ничего копировать не нужно — мы будем использовать Reference Variables.

---

## Шаг 3. Добавление Backend

1. **"+ New"** → **"GitHub Repo"** → выберите репозиторий `pneumaticworkflow`
2. Переименуйте сервис: нажмите на него → **Settings** → **Service Name** → `Backend`

### Настройка:

**Settings → Source:**
| Параметр | Значение |
|----------|----------|
| Root Directory | `/backend` |

**Settings → Build:**
| Параметр | Значение |
|----------|----------|
| Dockerfile Path | `Dockerfile.railway` |

> ⚠️ Если поле Dockerfile Path неактивно, добавьте переменную:  
> **Variables** → `RAILWAY_DOCKERFILE_PATH` = `Dockerfile.railway`

### Генерация домена:

**Settings → Networking → Public Networking** → **"Generate Domain"**

### Переменные:

Перейдите в **Variables** → нажмите **"RAW Editor"** → вставьте целиком:

```
POSTGRES_PASSWORD=${{Postgres.POSTGRES_PASSWORD}}
POSTGRES_REPLICA_PASSWORD=${{Postgres.POSTGRES_PASSWORD}}
CACHE_REDIS_URL=redis://default:${{Redis.REDISPASSWORD}}@redis.railway.internal:6379/0
AUTH_REDIS_URL=redis://default:${{Redis.REDISPASSWORD}}@redis.railway.internal:6379/1
CHANNELS_REDIS_URL=redis://default:${{Redis.REDISPASSWORD}}@redis.railway.internal:6379/2
SESSION_REDIS_URL=redis://default:${{Redis.REDISPASSWORD}}@redis.railway.internal:6379/3
CELERY_BROKER_URL=redis://default:${{Redis.REDISPASSWORD}}@redis.railway.internal:6379/4
BACKEND_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
FRONTEND_URL=https://${{Frontend.RAILWAY_PUBLIC_DOMAIN}}
FORMS_URL=https://${{Frontend.RAILWAY_PUBLIC_DOMAIN}}
ALLOWED_HOSTS=${{RAILWAY_PUBLIC_DOMAIN}} ${{RAILWAY_PRIVATE_DOMAIN}} localhost
CORS_ORIGIN_WHITELIST=https://${{Frontend.RAILWAY_PUBLIC_DOMAIN}} https://${{RAILWAY_PUBLIC_DOMAIN}}
```

> 💡 `${{...}}` — это Reference Variables. Railway автоматически подставит реальные значения (пароли, домены). Ничего копировать вручную не нужно!

Нажмите **"Update Variables"**.

---

## Шаг 4. Добавление Frontend

1. **"+ New"** → **"GitHub Repo"** → тот же репозиторий `pneumaticworkflow`
2. Переименуйте → `Frontend`

### Настройка:

**Settings → Source:**
| Параметр | Значение |
|----------|----------|
| Root Directory | `/frontend` |

**Settings → Build:**
| Параметр | Значение |
|----------|----------|
| Dockerfile Path | `Dockerfile.railway` |

### Генерация домена:

**Settings → Networking → Public Networking** → **"Generate Domain"**

### Переменные:

**Variables** → **"RAW Editor"** → вставьте:

```
BACKEND_URL=https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}
WSS_URL=wss://${{Backend.RAILWAY_PUBLIC_DOMAIN}}
```

Нажмите **"Update Variables"**.

---

## Шаг 5. Готово! 🎉

Railway автоматически запустит деплой обоих сервисов.

### Проверка (через 3-5 минут):

**Backend:**  
Откройте `https://<ваш-backend-домен>/accounts/user`  
Ожидаемый ответ:
```json
{"detail": "Authentication credentials were not provided."}
```

**Frontend:**  
Откройте `https://<ваш-frontend-домен>`  
Должна появиться страница входа/регистрации.

---

## 📝 Что где находится

### Файлы в репозитории:

```
📁 pneumaticworkflow/
├── backend/
│   ├── Dockerfile              ← для локальной разработки (docker-compose)
│   └── Dockerfile.railway      ← для Railway (с ENV, COPY, CMD)
├── frontend/
│   ├── Dockerfile              ← для локальной разработки (docker-compose)
│   └── Dockerfile.railway      ← для Railway (с ENV, webpack build, CMD)
└── deploy/
    └── RAILWAY_DEPLOY.md       ← эта инструкция
```

### Переменные — 3 уровня:

| Уровень | Что содержит | Пример |
|---------|-------------|--------|
| **Dockerfile.railway** (ENV) | Значения по умолчанию | `BILLING=no`, `SIGNUP=yes` |
| **Railway Dashboard** | Пароли и URL через ссылки | `${{Postgres.POSTGRES_PASSWORD}}` |
| **Railway автоматически** | Служебные переменные | `PORT`, `RAILWAY_PUBLIC_DOMAIN` |

> Dashboard переменные **перекрывают** Dockerfile ENV.

---

## ❓ Частые проблемы

### `502 Application failed to respond`
**Причина:** Backend не может подключиться к Postgres или Redis.  
**Решение:** 
- Проверьте что Postgres и Redis запущены (зелёный статус)
- Проверьте переменные — `${{Postgres.POSTGRES_PASSWORD}}` должен показывать реальное значение, а не `${{...}}`

### `Failed to lookup view "main"`
**Причина:** Webpack не собрал клиентские файлы.  
**Решение:** Убедитесь что Dockerfile Path = `Dockerfile.railway`

### Backend зависает после `Starting Container`
**Причина:** DNS `postgres.railway.internal` не резолвится.  
**Решение:** Подождите 1-2 минуты — Private Networking иногда стартует с задержкой. Или нажмите Redeploy.

### `Networking settings temporarily unavailable`
**Причина:** Временная проблема Railway.  
**Решение:** Подождите 5-10 минут.

---

## 🔧 Railway CLI (опционально)

```bash
# Установка
npm install -g @railway/cli

# Вход
railway login

# Привязка к проекту
railway link

# Логи
railway logs --service Backend

# Переменные
railway variables --service Backend --kv

# Redeploy
railway redeploy --yes
```
