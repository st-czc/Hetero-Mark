#!/bin/bash
#
# Generate the Hetero-Mark knn dataset in the current directory.
#
# Run this script inside hmark-data/knn on the board:
#   cd hmark-data/knn
#   bash gen_knn_data.sh 10000    # record count (default 10000)
#
# Produces:
#   filelist.<N>.txt  - one db file path per line (absolute, so the benchmark
#                       can open it regardless of its working directory)
#   db.<N>.txt        - synthetic records, 48 chars each
#
# The record layout must match KnnBenchmark::loadData() in
# src/knn/knn_benchmark.cc:
#   - each record is read as 48 chars (+ newline) via fgets(recString, 49)
#   - lat is parsed from columns 28..32 (5 chars, atof)
#   - lng is parsed from columns 33..37 (5 chars, atof)
#
set -e

NUM_RECORDS=${1:-10000}
if ! [[ "$NUM_RECORDS" =~ ^[0-9]+$ ]]; then
  echo "Error: record count must be a non-negative integer" >&2
  exit 1
fi

DIR="$(pwd)"

cat > "filelist.${NUM_RECORDS}.txt" <<EOF
$DIR/db.${NUM_RECORDS}.txt
EOF

awk -v n="$NUM_RECORDS" 'BEGIN{
  srand(42);
  for (i = 0; i < n; i++)
    printf "aaaaaaaaaaaaaaaaaaaaaaaaaaaa%05.2f%05.2fbbbbbbbbbb\n",
           rand()*90, rand()*90;
}' > "db.${NUM_RECORDS}.txt"

echo "generated filelist.${NUM_RECORDS}.txt and db.${NUM_RECORDS}.txt ($NUM_RECORDS records) in $DIR"
