#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run-subscriber.sh [build-dir]
BUILD_DIR="${1:-build}"
BIN_PATH="${BUILD_DIR}/bin/cpp-subscriber"

if [ ! -x "${BIN_PATH}" ]; then
  echo "Subscriber binary not found in ${BUILD_DIR}/bin. Build first with:"
  echo "  mkdir -p ${BUILD_DIR} && cd ${BUILD_DIR} && cmake .. -DAERON_BUILD_DIR=/path/to/aeron/build && cmake --build ."
  exit 1
fi

if [ -n "${AERON_BUILD_DIR:-}" ]; then
  AERON_LIB_DIR="${AERON_BUILD_DIR}/lib"
else
  AERON_LIB_DIR="${BUILD_DIR}/deps/lib"
fi

# Include Aeron native libs in LD_LIBRARY_PATH if the directory exists
if [ -d "${AERON_LIB_DIR}" ]; then
  export LD_LIBRARY_PATH="${AERON_LIB_DIR}:${LD_LIBRARY_PATH:-}"
fi

exec "${BIN_PATH}"
