#!/bin/bash
set -e

echo "=== Starting Backend ==="
echo "Memory info:"
cat /proc/meminfo | head -5
echo "=== Running migrations ==="
python manage.py migrate 2>&1 || echo "Migration failed with code: $?"

echo "=== Starting Gunicorn ==="
exec gunicorn src.asgi:application \
    --workers 1 \
    -k uvicorn.workers.UvicornWorker \
    --worker-tmp-dir /dev/shm \
    --bind 0.0.0.0:${PORT:-8000} \
    --timeout 200 \
    --log-level debug \
    --capture-output \
    --error-logfile - \
    --access-logfile -
