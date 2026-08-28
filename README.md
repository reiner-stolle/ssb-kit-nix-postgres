# SSB PostgreSQL Benchmark Environment

A reproducible local environment for the **Star Schema Benchmark (SSB)** using PostgreSQL and the SSB `dbgen` data generator.

The repository contains everything required to generate SSB datasets, run PostgreSQL locally, load the data, and execute benchmark queries.

Generated data and PostgreSQL files are stored locally under `.local/`.

## Requirements

- Linux
- Nix with flakes enabled
- Git

Enter the development environment:

```bash
nix develop
```

The Nix environment provides the required PostgreSQL and build tools.

## Project structure

```text
ssb-kit/
├── dbgen/                 # SSB data generator
├── queries/               # Benchmark queries
├── scripts/
│   ├── pg_schema.sql      # PostgreSQL table definitions
│   ├── pg_load.sql        # Data loading commands
│   └── drop.sql           # Removes benchmark tables
├── generate-sf.sh         # Generates an SSB dataset
├── setup-db.sh            # Initializes and starts PostgreSQL
├── load-sf.sh             # Creates the schema and loads a dataset
├── stop-db.sh             # Stops PostgreSQL
├── flake.nix              # Nix development environment
├── flake.lock             # Locked Nix dependencies
└── .local/                # Local data and database files (ignored by Git)
```

## Quick start

### 1. Enter the development environment

```bash
nix develop
```

### 2. Generate an SSB dataset

Generate SF1:

```bash
./generate-sf.sh 1
```

The generated files are stored in:

```text
.local/data/sf1/
```

The directory contains:

```text
customer.tbl
date.tbl
lineorder.tbl
part.tbl
supplier.tbl
```

Other scale factors can be generated in the same way:

```bash
./generate-sf.sh 10
./generate-sf.sh 100
```

The scale factor is passed directly to `dbgen`.

### 3. Start PostgreSQL

```bash
./setup-db.sh
```

On the first run, this initializes a new PostgreSQL database cluster.

On subsequent runs, it starts the existing cluster if it is not already running.

The local PostgreSQL instance uses:

```text
Database: ssb
Port:     5433
Socket:   .local/postgres/socket
Data:     .local/postgres/data
```

Port `5433` is used to avoid conflicts with PostgreSQL installations using the default port `5432`.

### 4. Load the dataset

Load SF1:

```bash
./load-sf.sh 1
```

This creates the database schema and loads the generated data into PostgreSQL.

The resulting tables are:

```text
dim_date
customer
part
supplier
lineorder
```

### 5. Connect to PostgreSQL

```bash
psql -p 5433 -h "$PWD/.local/postgres/socket" -d ssb
```

You should see:

```text
ssb=#
```

You can verify the tables with:

```sql
\dt
```

## Verify the installation

Run the following query:

```sql
SELECT
    SUM(lo_extendedprice * lo_discount) AS revenue
FROM lineorder
JOIN dim_date
    ON lo_orderdate = d_datekey
WHERE d_year = 1993
  AND lo_discount BETWEEN 1 AND 3
  AND lo_quantity < 25;
```

For the generated SF1 dataset, the expected result is:

```text
446268068091
```

This verifies that the dataset was generated, the schema was created, and the data was loaded correctly.

## Working with different scale factors

Each scale factor is stored separately:

```text
.local/data/
├── sf1/
├── sf10/
└── sf100/
```

To generate another dataset:

```bash
./generate-sf.sh 10
```

Before loading a different scale factor into PostgreSQL, remove the existing tables:

```bash
psql \
  -p 5433 \
  -h "$PWD/.local/postgres/socket" \
  -d ssb \
  -f scripts/drop.sql
```

Then load the new dataset:

```bash
./load-sf.sh 10
```

## Stopping PostgreSQL

Stop the local database with:

```bash
./stop-db.sh
```

The database files are preserved and can be started again with:

```bash
./setup-db.sh
```

## Resetting PostgreSQL

To completely remove the local PostgreSQL database:

```bash
./stop-db.sh
rm -rf .local/postgres
```

The next time you run:

```bash
./setup-db.sh
```

a new PostgreSQL cluster will be initialized.

**Warning:** removing `.local/postgres` permanently deletes the local database.

## Generated data and Git

Generated datasets can be hundreds of megabytes or more, so they are not stored in Git.

All local runtime data is stored under:

```text
.local/
```

and `.local/` is included in `.gitignore`.

This keeps the repository small while allowing the database and datasets to be recreated from the repository.

A clean checkout can therefore be reproduced with:

```bash
nix develop
./generate-sf.sh 1
./setup-db.sh
./load-sf.sh 1
```

## Reproducibility

The repository tracks the components required to reproduce the environment:

- SSB generator source code
- PostgreSQL schema
- Loading scripts
- Benchmark queries
- Nix development environment
- Locked Nix dependencies

Generated datasets and PostgreSQL database files are local build/runtime artifacts and are intentionally excluded from Git.

The generator prints SHA-256 checksums for generated `.tbl` files. These can be used to verify that two generated datasets are byte-for-byte identical.

## Configuration

The scripts use repository-relative paths by default and do not contain machine-specific paths.

The following environment variables can be used to override the defaults:

```text
SSB_DATA_DIR
SSB_PGPORT
SSB_PGSOCKET
SSB_DBNAME
```

For example:

```bash
SSB_PGPORT=5434 ./setup-db.sh
```

or:

```bash
SSB_DATA_DIR=/data/ssb ./generate-sf.sh 10
```

## Typical workflow

For a fresh environment:

```bash
nix develop

./generate-sf.sh 1

./setup-db.sh

./load-sf.sh 1

psql -p 5433 -h "$PWD/.local/postgres/socket" -d ssb
```

For subsequent sessions, PostgreSQL only needs to be started if it is not already running:

```bash
./setup-db.sh
```

Then connect with:

```bash
psql -p 5433 -h "$PWD/.local/postgres/socket" -d ssb
```
