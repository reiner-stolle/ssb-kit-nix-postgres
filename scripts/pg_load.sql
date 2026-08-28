\if :{?data_dir}
\else
  \echo 'ERROR: data_dir was not provided'
  \echo 'Usage: psql -v data_dir=/path/to/sf1 -f scripts/pg_load.sql'
  \quit
\endif

\set d :data_dir '/date.tbl'
\set c :data_dir '/customer.tbl'
\set p :data_dir '/part.tbl'
\set s :data_dir '/supplier.tbl'
\set l :data_dir '/lineorder.tbl'

\echo 'Loading SSB data from :'data_dir

COPY dim_date  FROM :'d' DELIMITER '|' NULL '';
COPY customer  FROM :'c' DELIMITER '|' NULL '';
COPY part      FROM :'p' DELIMITER '|' NULL '';
COPY supplier  FROM :'s' DELIMITER '|' NULL '';
COPY lineorder FROM :'l' DELIMITER '|' NULL '';
