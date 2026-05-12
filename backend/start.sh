#!/bin/bash
set -e

echo "=== Running migrations ==="
python manage.py migrate

echo "=== Collecting static files ==="
python manage.py collectstatic --no-input || echo "Warning: collectstatic failed (non-critical)"

echo "=== Initializing periodic tasks ==="
python manage.py init_periodic_tasks || echo "Warning: init_periodic_tasks failed (non-critical)"

echo "=== Compiling messages ==="
python manage.py compilemessages || echo "Warning: compilemessages failed (non-critical)"

echo "=== Starting Gunicorn on port ${PORT:-8000} ==="
exec gunicorn src.asgi:application \
    --workers 1 \
    -k uvicorn.workers.UvicornWorker \
    --worker-tmp-dir /dev/shm \
    --bind 0.0.0.0:${PORT:-8000} \
    --timeout 200 \
    --error-logfile - \
    --access-logfile -
