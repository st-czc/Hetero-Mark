#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

THEROCK=/data2/home2/chenzhenchuan/WorkSpace/HIP/TheRock

CMAKE_ARGS=(
  -DCMAKE_TOOLCHAIN_FILE=${THEROCK}/install/lib/cuspv/cmake/cuspv/cuda-on-hip.cmake
  -DHMARK_BUILD_CUDA=On
  -DHMARK_BUILD_HIP=Off
  -DCMAKE_BUILD_TYPE=Release
  -DHMARK_HIPCPU_AOT=On
)

if [ -n "${OPENCV_ENV:-}" ]; then
  source "${OPENCV_ENV}"
  CMAKE_ARGS+=(
    -DOpenCV_DIR="$CV_ROOT/usr/lib/$(gcc -dumpmachine)/cmake/opencv4"
  )
fi

if [ ! -d build ]; then
  cmake -S . -B build -GNinja "${CMAKE_ARGS[@]}"
fi

cmake --build build -j "$(nproc)" -- -k 0
