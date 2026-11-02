#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
source /data2/home2/chenzhenchuan/WorkSpace/.local/hetero-mark-depends/env.sh

if [ ! -d build ]; then
  cmake -S . -B build -GNinja \
    -DCMAKE_TOOLCHAIN_FILE=/data2/home2/chenzhenchuan/WorkSpace/HIP/TheRock/install/lib/cuspv/cmake/cuspv/cuda-on-hip.cmake \
    -DHMARK_BUILD_CUDA=On -DHMARK_BUILD_HIP=Off \
    -DCMAKE_BUILD_TYPE=Release \
    -DOpenCV_DIR="$CV_ROOT/usr/lib/x86_64-linux-gnu/cmake/opencv4"
fi

cmake --build build -j "$(nproc)" -- -k 0
