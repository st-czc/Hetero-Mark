#!/bin/bash
set -e

DATASET_PATH="dataset/hmark-data"

MODE=""       # "" = normal run, "time", "ksize", or "dry"
PERF=0
REPEAT=8
VERIFY=""
BS_CHUNK=""
CASES=()
WORK_DIR="Hetero-Mark"

# Parse command-line arguments.
while [ $# -gt 0 ]; do
  case "$1" in
    -p|--perf)
      PERF=1
      shift
      ;;
    -d|--debug)
      MODE="${2:?$1 requires a value (time or ksize)}"
      shift 2
      ;;
    --dry)
      MODE="dry"
      shift
      ;;
    -r)
      REPEAT="${2:?-r requires a value}"
      shift 2
      ;;
    -v)
      VERIFY="-v"
      shift
      ;;
    --bs-chunk)
      BS_CHUNK="${2:?--bs-chunk requires a value}"
      shift 2
      ;;
    -c|--case)
      CASES+=("${2:?$1 requires a value}")
      shift 2
      ;;
    -w)
      WORK_DIR="${2:?-w requires a value}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [-p|--perf] [-d time|ksize] [--dry] [-r N] [-v] [--bs-chunk N] [-c CASE ...] [-w DIR]" >&2
      exit 1
      ;;
  esac
done

case "$MODE" in
  time)
    export POCL_DEBUG=timing
    mkdir -p performance/"$WORK_DIR"
    ;;
  ksize)
    export POCL_DEBUG=general
    mkdir -p performance/"$WORK_DIR"
    ;;
  dry|"") ;;
  *)
    echo "Unknown debug mode: $MODE (expected time or ksize)" >&2
    exit 1
    ;;
esac

if [ "$MODE" != "dry" ] && [ ! -d "$DATASET_PATH" ]; then
  mkdir -p dataset
  if [ ! -f "dataset/hmark-data.zip" ]; then
    echo "Download Hetero Mark dataset"
    wget -O dataset/hmark-data.zip https://heteromark.s3.us-east-2.amazonaws.com/hmark-data.zip
  fi
  echo "Unzip Hetero Mark dataset"
  unzip -q dataset/hmark-data.zip -d dataset
fi

# Generate the knn dataset if missing, regardless of perf mode or CASES.
if [ "$MODE" != "dry" ] && [ ! -f "$DATASET_PATH/knn/filelist.10000.txt" ]; then
  mkdir -p "$DATASET_PATH/knn"
  cp "$WORK_DIR/tools/gen_knn_data.sh" "$DATASET_PATH/knn/"
  (
    cd "$DATASET_PATH/knn"
    bash gen_knn_data.sh 10000
    bash gen_knn_data.sh 1000000
  )
fi

if [ ${#CASES[@]} -eq 0 ]; then
  CASES=(aes be bs bst ep fir ga hist kmeans knn pr)
fi

for TestCase in "${CASES[@]}"; do
  EXE="$WORK_DIR/build/src/$TestCase/cuda/${TestCase}_cuda"
  if [ ! -x "$EXE" ]; then
    echo "Warning: $EXE not found, skipping $TestCase"
    continue
  fi

  if [ "$PERF" -eq 1 ]; then
    case $TestCase in
    aes)    ARGS=(-i "$DATASET_PATH/aes/32MB.data" -k "$DATASET_PATH/aes/key.data") ;;
    be)     ARGS=(-i "$DATASET_PATH/be/1920x1080.mp4" -m 100) ;;
    bs)     ARGS=(-x 8388608 --chunk "${BS_CHUNK:-4096}") ;;
    bst)    ARGS=() ;;
    ep)     ARGS=(-x 16384 -m 20) ;;  # reduced to 50% workload; original: -x 32768 -m 20
    fir)    ARGS=(-x 8192) ;;
    ga)     ARGS=(-i "$DATASET_PATH/ga/1048576_1024.data") ;;
    hist)   ARGS=(-x 33554432) ;;
    kmeans) ARGS=(-i "$DATASET_PATH/kmeans/1000000_34.txt") ;;
    knn)    ARGS=(-i "$DATASET_PATH/knn/filelist.1000000.txt") ;;
    pr)     ARGS=(-i "$DATASET_PATH/pr/16384.data") ;;
    *)
      echo "unknown case: $TestCase"
      continue
      ;;
    esac
  else
    case $TestCase in
    aes)    ARGS=(-i "$DATASET_PATH/aes/1KB.data" -k "$DATASET_PATH/aes/key.data") ;;
    be)     ARGS=(-i "$DATASET_PATH/be/320x180.mp4" -m 100) ;;
    bs)     ARGS=(-x 131072 --chunk "${BS_CHUNK:-0}") ;;
    bst)    ARGS=() ;;
    ep)     ARGS=(-x 1024 -m 20) ;;
    fir)    ARGS=(-x 1024) ;;
    ga)     ARGS=(-i "$DATASET_PATH/ga/1024_64.data") ;;
    hist)   ARGS=(-x 65536) ;;
    kmeans) ARGS=(-i "$DATASET_PATH/kmeans/100_34.txt") ;;
    knn)    ARGS=(-i "$DATASET_PATH/knn/filelist.10000.txt") ;;
    pr)     ARGS=(-i "$DATASET_PATH/pr/1024.data") ;;
    *)
      echo "unknown case: $TestCase"
      continue
      ;;
    esac
  fi

  ARGS=(-t -r "$REPEAT" -q "${ARGS[@]}" ${VERIFY})

  echo "Running: $EXE"
  if [ "$MODE" = "dry" ]; then
    printf '%q ' "$EXE" "${ARGS[@]}"
    echo
  elif [ "$MODE" = "time" ]; then
    "$EXE" "${ARGS[@]}" 2> >(grep TIMING > "performance/$WORK_DIR/$TestCase.timing.txt")
  elif [ "$MODE" = "ksize" ]; then
    "$EXE" "${ARGS[@]}" 2> >(grep "Preparing kernel" > "performance/$WORK_DIR/$TestCase.ksize.txt")
  else
    "$EXE" "${ARGS[@]}"
  fi
  echo
done
