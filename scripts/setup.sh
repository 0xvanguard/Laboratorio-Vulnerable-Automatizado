#!/usr/bin/env bash
# =============================================================================
# setup.sh - prepara el entorno y arranca el laboratorio por primera vez.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Verificando dependencias..."
command -v docker >/dev/null || { echo "[ERR] Necesitas Docker instalado."; exit 1; }
docker compose version >/dev/null 2>&1 || {
  echo "[ERR] Necesitas el plugin de Docker Compose (docker compose v2)."
  exit 1
}

if [[ ! -f .env ]]; then
  echo "==> Creando .env a partir de .env.example"
  cp .env.example .env
fi

echo "==> Construyendo imagenes..."
docker compose build

echo "==> Levantando servicios..."
docker compose up -d

echo
echo "Laboratorio listo."
LAB_HTTP_PORT="$(grep ^LAB_HTTP_PORT .env | cut -d= -f2)"
echo "  Landing: http://localhost:${LAB_HTTP_PORT:-8080}/"
echo
echo "Tip: ejecuta 'make health' en unos segundos para verificar."
