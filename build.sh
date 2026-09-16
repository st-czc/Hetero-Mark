#!/bin/bash

set -e

DEPS=$(realpath ${HOME}/WorkSpace2/.local/hetero-mark-depends)

source ${DEPS}/env.sh

cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_COMPILER=$(which nvcc) \
  -DOpenCV_DIR=${DEPS}/usr/lib/x86_64-linux-gnu/cmake/opencv4 \
  -DCOMPILE_CUDA=On \
  -DCUDA_CUDART_LIBRARY="$(dirname $(which nvcc))/../lib/libcudart.so" \
  -DCUDA_TOOLKIT_INCLUDE="$(dirname $(which nvcc))/../include" \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_CXX_FLAGS="-I${DEPS}/usr/include/opencv4"


cmake --build build --parallel 8 --

find build/src -name '*_cuda'
