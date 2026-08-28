'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DATA_DIR="${SSB_DATA_DIR:-$ROOT/.local/data}"
PGSOCKET="${SSB_PGSOCKET:-$ROOT/.local/postgres/socket}"
PGPORT="${SSB_PGPORT:-5433}"
DBNAME="${SSB_DBNAME:-ssb}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <scale-factor>"
    exit 1
fi

SF="$1"
DATA="$DATA_DIR/sf${SF}"

if [[ ! -d "$DATA" ]]; then
    echo "Error: data directory does not exist:"
    echo "  $DATA"
    echo
    echo "Generate it first:"
    echo "  ./generate-sf.sh $SF"
    exit 1
fi

echo "SSB database loader"
echo "-------------------"
echo "Scale      : $SF"
echo "Data       : $DATA"
echo "Database   : $DBNAME"
echo "Port       : $PGPORT"
echo "Socket     : $PGSOCKET"
echo

echo "==> Loading schema"

psql \
    -p "$PGPORT" \
    -h "$PGSOCKET" \
    -d "$DBNAME" \
    -f "$ROOT/scripts/pg_schema.sql"

echo "==> Loading data"

psql \
    -p "$PGPORT" \
    -h "$PGSOCKET" \
    -d "$DBNAME" \
    -v "data_dir=$DATA" \
    -f "$ROOT/scripts/pg_load.sql"

echo
echo "==> Row counts"

psql \
    -p "$PGPORT" \
    -h "$PGSOCKET" \
    -d "$DBNAME" \
    -c "
        SELECT 'dim_date' AS table_name, count(*) FROM dim_date
        UNION ALL
        SELECT 'customer', count(*) FROM customer
        UNION ALL
        SELECT 'part', count(*) FROM part
        UNION ALL
        SELECT 'supplier', count(*) FROM supplier
        UNION ALL
        SELECT 'lineorder', count(*) FROM lineorder
        ORDER BY table_name;
    "
