#!/bin/bash
set -euo pipefail

echo "[initdb] Checking for 10_postgis.sh script..."
if [ -f /docker-entrypoint-initdb.d/10_postgis.sh ]; then
  if grep -q "OUR_OWN_10_POSTGIS" /docker-entrypoint-initdb.d/10_postgis.sh 2>/dev/null; then
    echo "[initdb] Found our own 10_postgis.sh; will not disable."
  else
    echo "[initdb] Disabling upstream 10_postgis.sh to avoid '--dbname=template_postgis' error."
    mv /docker-entrypoint-initdb.d/10_postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh.disabled || true
  fi
else
  echo "[initdb] No 10_postgis.sh found."
fi

echo "[initdb] Ensuring PostGIS extension will be created by our SQL (01_init.sql)."

# Sicherstellen, dass das Hauptskript nicht fehlschlägt
touch /docker-entrypoint-initdb.d/10_postgis.sh
chmod +x /docker-entrypoint-initdb.d/10_postgis.sh
