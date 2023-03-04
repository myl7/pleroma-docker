#!/bin/ash
set -euo pipefail

echo "-- Generating config..."
mix pleroma.instance gen
cp config/generated_config.exs /config/prod.secret.exs
# For Postgres init script
cp config/setup_db.psql /config/setup_db.sql || true
