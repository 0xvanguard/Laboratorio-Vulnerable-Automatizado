#!/usr/bin/env bash
# =============================================================================
# health.sh - comprueba que los servicios del laboratorio respondan.
# =============================================================================
set -uo pipefail

cd "$(dirname "$0")/.."

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env
fi

LAB_HTTP_PORT="${LAB_HTTP_PORT:-8080}"
LAB_DVWA_PORT="${LAB_DVWA_PORT:-8081}"
LAB_JUICE_PORT="${LAB_JUICE_PORT:-8082}"
LAB_STATUS_PORT="${LAB_STATUS_PORT:-8088}"

check() {
  local name="$1" url="$2" expected="${3:-200}"
  local code
  code="$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" || echo "000")"
  if [[ "$code" == "$expected" || "$code" =~ ^(200|301|302)$ ]]; then
    printf "  [OK]  %-22s %s (%s)\n" "$name" "$url" "$code"
  else
    printf "  [FAIL] %-21s %s (%s)\n" "$name" "$url" "$code"
  fi
}

echo "==> Verificando endpoints del laboratorio"
check "Landing"      "http://localhost:${LAB_HTTP_PORT}/"
check "Health"       "http://localhost:${LAB_HTTP_PORT}/health" 200
check "DVWA  /dvwa/" "http://localhost:${LAB_HTTP_PORT}/dvwa/login.php"
check "DVWA  directo" "http://localhost:${LAB_DVWA_PORT}/login.php"
check "Juice /juice/" "http://localhost:${LAB_HTTP_PORT}/juice/"
check "Juice directo" "http://localhost:${LAB_JUICE_PORT}/"
check "phpMyAdmin"   "http://localhost:${LAB_HTTP_PORT}/dbadmin/"
check "Status"       "http://localhost:${LAB_HTTP_PORT}/nginx_status"
check "Status :port" "http://localhost:${LAB_STATUS_PORT}/"
check "Backups"      "http://localhost:${LAB_HTTP_PORT}/assets/backup.txt"

echo
echo "Hecho."
