#!/usr/bin/env bash
# =============================================================================
# reset.sh - apaga el laboratorio, borra volumenes y vuelve a levantarlo limpio.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Apagando contenedores y eliminando volumenes..."
docker compose down -v --remove-orphans || true

echo "==> Levantando de nuevo (datos frescos)..."
docker compose up -d --build

echo "==> Listo. Prueba 'make health'."
