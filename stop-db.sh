#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PGDATA="$ROOT/.local/postgres/data"

if [[ ! -f "$PGDATA/PG_VERSION" ]]; then
    echo "PostgreSQL has not been initialized."
    exit 0
fi

if pg_ctl -D "$PGDATA" status >/dev/null 2>&1; then
    echo "==> Stopping PostgreSQL"
    pg_ctl -D "$PGDATA" stop
else
    echo "PostgreSQL is not running."
fi
