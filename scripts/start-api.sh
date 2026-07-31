#!/usr/bin/env sh
set -eu

python ./scripts/ensure-app-db.py
alembic upgrade head
exec uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
