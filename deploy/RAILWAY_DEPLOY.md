# 🚀 Развёртывание PneumaticWorkflow на Railway

Полная инструкция по развёртыванию проекта с нуля на [Railway](https://railway.app).

---

## 📋 Что нужно перед началом

- Аккаунт на [GitHub](https://github.com) с форком или копией [pneumaticworkflow](https://github.com/pneumaticapp/pneumaticworkflow)
- Аккаунт на [Railway](https://railway.app) (привязан к GitHub)
- Около 15-20 минут времени

---

## 📐 Архитектура

```
┌──────────────────────────────────────────────────┐
│                   Railway Project                 │
│                                                   │
│  ┌─────────┐  ┌──────────┐  ┌────────┐  ┌─────┐ │
│  │ Backend │  │ Frontend │  │Postgres│  │Redis│ │
│  │ Python  │  │  Node.js │  │  DB    │  │Cache│ │
│  │ Django  │  │ Express  │  │        │  │     │ │
│  └────┬────┘  └────┬─────┘  └────────┘  └─────┘ │
│       │            │                              │
│       └────────────┘                              │
│     Оба подключаются к Postgres и Redis           │
└──────────────────────────────────────────────────┘
```

**4 сервиса:**
| Сервис | Назначение | Источник |
|--------|-----------|----------|
| **Backend** | Django REST API + WebSocket | GitHub repo `/backend` |
| **Frontend** | Express SSR + React | GitHub repo `/frontend` |
| **Postgres** | База данных | Railway шаблон |
| **Redis** | Кэш, сессии, Celery, каналы | Railway шаблон |

---

## Шаг 1. Создание проекта в Railway

1. Откройте [railway.app](https://railway.app) и войдите через GitHub
2. Нажмите **"New Project"**
3. Выберите **"Empty Project"**
4. Назовите проект (например `pneumatic-workflow`)

![Новый проект](https://docs.railway.com/assets/images/new-project.png)

---

## Шаг 2. Добавление Postgres

1. В проекте нажмите **"+ New"** (правый верхний угол)
2. Выберите **"Database"**
3. Выберите **"Add PostgreSQL"**
4. Подождите ~30 секунд пока создастся

### Запишите данные подключения:
1. Нажмите на созданный сервис **Postgres**
2. Перейдите на вкладку **"Variables"**
3. Скопируйте и сохраните:
   - `POSTGRES_PASSWORD` — пароль (длинная строка)

> **Пример:** `tLsoLMVMPEkpynWPrELyUtTtYJBxeIZR`

---

## Шаг 3. Добавление Redis

1. Нажмите **"+ New"** → **"Database"** → **"Add Redis"**
2. Подождите ~30 секунд
3. Нажмите на сервис **Redis** → **"Variables"**
4. Скопируйте и сохраните:
   - `REDIS_PASSWORD` — пароль

> **Пример:** `hiLwpQAPoCpTXcdzeCaSFVOSIVLSfVQH`

---

## Шаг 4. Добавление Backend

1. Нажмите **"+ New"** → **"GitHub Repo"**
2. Выберите ваш репозиторий `pneumaticworkflow`
3. Railway создаст сервис — **переименуйте** его в `Backend`:
   - Нажмите на сервис → **Settings** → **Service Name** → `Backend`

### Настройка сборки:

В **Settings → Source:**
- **Root Directory** → `/backend`

В **Settings → Build:**
- **Builder** → Dockerfile (обычно автоматически)
- **Dockerfile Path** → `Dockerfile.railway`

> ⚠️ Если Dockerfile Path задаётся через переменную, добавьте в Variables:
> `RAILWAY_DOCKERFILE_PATH` = `Dockerfile.railway`

### Переменные окружения:

Перейдите в **Variables** → **"+ New Variable"** и добавьте:

#### Обязательные (замените значения на реальные):

```
POSTGRES_PASSWORD=<пароль из шага 2>
POSTGRES_REPLICA_PASSWORD=<тот же пароль из шага 2>
```

#### Redis URLs (замените `<REDIS_PASSWORD>` на пароль из шага 3):

```
CACHE_REDIS_URL=redis://default:<REDIS_PASSWORD>@redis.railway.internal:6379/0
AUTH_REDIS_URL=redis://default:<REDIS_PASSWORD>@redis.railway.internal:6379/1
CHANNELS_REDIS_URL=redis://default:<REDIS_PASSWORD>@redis.railway.internal:6379/2
SESSION_REDIS_URL=redis://default:<REDIS_PASSWORD>@redis.railway.internal:6379/3
CELERY_BROKER_URL=redis://default:<REDIS_PASSWORD>@redis.railway.internal:6379/4
```

> 💡 Все остальные переменные уже заданы как значения по умолчанию в `Dockerfile.railway`.
> Их не нужно добавлять вручную, если вас устраивают значения по умолчанию.

---

## Шаг 5. Генерация домена для Backend

1. **Backend → Settings → Networking → Public Networking**
2. Нажмите **"Generate Domain"**
3. Скопируйте сгенерированный домен

> **Пример:** `backend-production-24449.up.railway.app`

### Обновите переменные Backend:

```
BACKEND_URL=https://backend-production-XXXXX.up.railway.app
ALLOWED_HOSTS=backend-production-XXXXX.up.railway.app localhost
```

> ⚠️ Пока не заполняйте `FRONTEND_URL` — его мы получим на следующем шаге.

---

## Шаг 6. Добавление Frontend

1. Нажмите **"+ New"** → **"GitHub Repo"**
2. Выберите тот же репозиторий `pneumaticworkflow`
3. Переименуйте сервис в `Frontend`

### Настройка сборки:

В **Settings → Source:**
- **Root Directory** → `/frontend`

В **Settings → Build:**
- **Dockerfile Path** → `Dockerfile.railway`

> Или добавьте переменную: `RAILWAY_DOCKERFILE_PATH` = `Dockerfile.railway`

### Генерация домена:

1. **Frontend → Settings → Networking → Public Networking**
2. Нажмите **"Generate Domain"**
3. Скопируйте домен

> **Пример:** `frontend-production-1c3c.up.railway.app`

### Переменные Frontend:

```
BACKEND_URL=https://backend-production-XXXXX.up.railway.app
WSS_URL=wss://backend-production-XXXXX.up.railway.app
```

---

## Шаг 7. Обновление URL-ов в Backend

Теперь когда оба домена известны, вернитесь в **Backend → Variables** и добавьте:

```
FRONTEND_URL=https://frontend-production-XXXXX.up.railway.app
FORMS_URL=https://frontend-production-XXXXX.up.railway.app
CORS_ORIGIN_WHITELIST=https://frontend-production-XXXXX.up.railway.app https://backend-production-XXXXX.up.railway.app
```

---

## Шаг 8. Деплой!

После сохранения всех переменных Railway автоматически запустит деплой.

### Проверка Backend:

1. **Backend → Deployments** — дождитесь статуса **"SUCCESS"** (зелёный)
2. Откройте в браузере: `https://backend-production-XXXXX.up.railway.app/accounts/user`
3. Должен вернуться JSON:
```json
{"detail": "Authentication credentials were not provided."}
```
✅ Это значит Backend работает!

### Проверка Frontend:

1. **Frontend → Deployments** — дождитесь **"SUCCESS"**
2. Откройте: `https://frontend-production-XXXXX.up.railway.app`
3. Должна появиться страница входа/регистрации

✅ Всё работает!

---

## 🎉 Готово!

Зарегистрируйте первого пользователя и начните работать.

---

## 📝 Сводная таблица переменных

### Backend — нужно добавить вручную:

| Переменная | Значение | Откуда |
|-----------|----------|--------|
| `POSTGRES_PASSWORD` | `abc123...` | Postgres → Variables |
| `POSTGRES_REPLICA_PASSWORD` | `abc123...` | Postgres → Variables |
| `CACHE_REDIS_URL` | `redis://default:xyz@redis.railway.internal:6379/0` | Redis → Variables |
| `AUTH_REDIS_URL` | `redis://default:xyz@redis.railway.internal:6379/1` | Redis → Variables |
| `CHANNELS_REDIS_URL` | `redis://default:xyz@redis.railway.internal:6379/2` | Redis → Variables |
| `SESSION_REDIS_URL` | `redis://default:xyz@redis.railway.internal:6379/3` | Redis → Variables |
| `CELERY_BROKER_URL` | `redis://default:xyz@redis.railway.internal:6379/4` | Redis → Variables |
| `BACKEND_URL` | `https://backend-...up.railway.app` | Generated Domain |
| `FRONTEND_URL` | `https://frontend-...up.railway.app` | Generated Domain |
| `FORMS_URL` | `https://frontend-...up.railway.app` | Generated Domain |
| `ALLOWED_HOSTS` | `backend-...up.railway.app localhost` | Generated Domain |
| `CORS_ORIGIN_WHITELIST` | `https://frontend-... https://backend-...` | Generated Domains |

### Frontend — нужно добавить вручную:

| Переменная | Значение | Откуда |
|-----------|----------|--------|
| `BACKEND_URL` | `https://backend-...up.railway.app` | Backend Domain |
| `WSS_URL` | `wss://backend-...up.railway.app` | Backend Domain |

### Уже встроены в Dockerfile (не нужно добавлять):

```
ENVIRONMENT, DJANGO_SECRET_KEY, DJANGO_SETTINGS_MODULE, DJANGO_DEBUG,
LANGUAGE_CODE, RELEASE, ADMIN_PATH, SIGNUP, POSTGRES_HOST, POSTGRES_PORT,
POSTGRES_DB, POSTGRES_USER, BILLING, ANALYTICS, CAPTCHA, EMAIL, PUSH,
STORAGE, AI, GOOGLE_AUTH, MS_AUTH, SSO_AUTH, VERIFICATION_CHECK,
ENABLE_LOGGING, CORS_ALLOW_CREDENTIALS, CORS_ORIGIN_ALLOW_ALL,
NODE_ENV (Frontend)
```

---

## ❓ Частые проблемы

### Backend: `502 Application failed to respond`
- **Причина:** Postgres или Redis недоступен
- **Решение:** Проверьте что Postgres и Redis запущены (зелёный статус). Проверьте пароли в переменных.

### Frontend: `Failed to lookup view "main"`
- **Причина:** Webpack не собрал клиентские файлы
- **Решение:** Убедитесь что Dockerfile Path = `Dockerfile.railway` (он содержит `npm run build-client:prod`)

### Backend зависает после `Starting Container`
- **Причина:** Не удаётся подключиться к Postgres
- **Решение:** Проверьте `POSTGRES_HOST=postgres.railway.internal` и правильность `POSTGRES_PASSWORD`

### Networking settings temporarily unavailable
- **Причина:** Временная проблема Railway
- **Решение:** Подождите 5-10 минут и нажмите Redeploy

---

## 🔧 Полезные команды Railway CLI

```bash
# Установка CLI
npm install -g @railway/cli

# Вход
railway login

# Привязка к проекту
railway link

# Просмотр переменных
railway variables --service Backend --kv

# Установка переменной
railway variable set KEY=VALUE --service Backend

# Просмотр логов
railway logs --service Backend

# Redeploy
railway redeploy --yes
```
