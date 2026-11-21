#!/usr/bin/env bash
# Linux / macOS / WSL runner. Requires Docker only.
set -e
cd "$(dirname "$0")"
mkdir -p output && chmod 777 output
if docker compose version >/dev/null 2>&1; then DC="docker compose"; else DC="docker-compose"; fi
BL="docker exec hive4 beeline -u jdbc:hive2://localhost:10000/"

$DC up -d
echo "Waiting for HiveServer2 (first start can take 1-2 minutes)..."
ok=0
for i in $(seq 1 60); do
  if $BL -e "SHOW DATABASES;" >/dev/null 2>&1; then ok=1; break; fi
  sleep 5
done
[ "$ok" = 1 ] || { echo "HiveServer2 did not start. Check: docker logs hive4"; exit 1; }

$BL -f /hql/01_create_tables.hql
$BL -f /hql/02_analysis.hql | tee output/console_output.txt
$BL -f /hql/03_export.hql
echo "Done. Console output: output/console_output.txt   CSV exports: output/*_summary/"
