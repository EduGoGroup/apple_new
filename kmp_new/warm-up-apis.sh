#!/bin/bash
# warm-up-apis.sh
# Despierta las 3 APIs de EduGo en staging antes de pruebas.
# Uso: ./warm-up-apis.sh

IAM_URL="https://edugo-api-iam-platform.wittyhill-f6d656fb.eastus.azurecontainerapps.io"
ADMIN_URL="https://edugo-api-admin-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io"
MOBILE_URL="https://edugo-api-mobile-new.wittyhill-f6d656fb.eastus.azurecontainerapps.io"

HEALTH_PATH="/api/v1/health"
TIMEOUT=120

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ping_api() {
  local name=$1
  local base_url=$2
  local tmpfile
  tmpfile=$(mktemp)

  echo -n "  $name ... "

  response=$(curl -s -o "$tmpfile" -w "%{http_code}" \
    --max-time $TIMEOUT \
    "$base_url$HEALTH_PATH" 2>/dev/null)

  if [ "$response" = "200" ]; then
    echo -e "${GREEN}OK${NC} (HTTP $response)"
  elif [ "$response" = "000" ]; then
    echo -e "${RED}TIMEOUT / sin respuesta${NC} (>${TIMEOUT}s)"
  else
    body=$(head -c 200 "$tmpfile" 2>/dev/null)
    echo -e "${YELLOW}HTTP $response${NC} → $body"
  fi

  rm -f "$tmpfile"
}

echo ""
echo "========================================"
echo "  EduGo API Warm-up  [staging]"
echo "========================================"
echo ""

ping_api "IAM Platform" "$IAM_URL"
ping_api "Admin API   " "$ADMIN_URL"
ping_api "Mobile API  " "$MOBILE_URL"

echo ""
echo "Listo. Ya puedes correr la app."
echo ""
