#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run-subscriber.sh [build-dir]
BUILD_DIR="${1:-build}"

if [ ! -x "${BUILD_DIR}/bin/cpp-subscriber" ]; then
  echo "Subscriber binary not found in ${BUILD_DIR}/bin. Build first with:"
  echo "  mkdir -p ${BUILD_DIR} && cd ${BUILD_DIR} && cmake .. -DAERON_BUILD_DIR=/path/to/aeron/build && cmake --build ."
  exit 1
fi

# If Aeron native libs are in a non-standard location, set LD_LIBRARY_PATH accordingly.
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"":${AERON_BUILD_DIR:-/home/saijagannath/Documents/code/java_code/aeron/build}/lib"

exec "${BUILD_DIR}/bin/cpp-subscriber"
