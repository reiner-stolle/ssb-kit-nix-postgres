#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PGROOT="$ROOT/.local/postgres"
PGDATA="$PGROOT/data"
PGSOCKET="$PGROOT/socket"
PGPORT="${SSB_PGPORT:-5433}"
DBNAME="${SSB_DBNAME:-ssb}"

mkdir -p "$PGROOT"
mkdir -p "$PGSOCKET"

if [[ ! -f "$PGDATA/PG_VERSION" ]]; then
    echo "==> Initializing PostgreSQL"
    initdb -D "$PGDATA"
fi

if pg_ctl -D "$PGDATA" status >/dev/null 2>&1; then
    echo "PostgreSQL is already running."
else
    echo "==> Starting PostgreSQL on port $PGPORT"

    pg_ctl \
        -D "$PGDATA" \
        -o "-p $PGPORT -k $PGSOCKET" \
        -l "$PGROOT/postgres.log" \
        start
fi

echo "==> Creating database '$DBNAME'"

createdb \
    -p "$PGPORT" \
    -h "$PGSOCKET" \
    "$DBNAME" 2>/dev/null || true

echo
echo "PostgreSQL ready."
echo "Socket : $PGSOCKET"
echo "Port   : $PGPORT"
echo "Database: $DBNAME"
