#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONF_FILE="${ROOT_DIR}/scripts/run.conf"

if [ $# -ge 1 ]; then
  CONF_FILE="$1"
fi

if [ ! -f "$CONF_FILE" ]; then
  echo "Config file not found: $CONF_FILE"
  exit 1
fi

echo "Using config: $CONF_FILE"

# read key=value pairs
declare -A cfg
while IFS='=' read -r key value; do
  key="$(echo "$key" | tr -d ' \t\r')"
  value="$(echo "$value" | sed 's/^ *//;s/ *$//')"
  if [[ -z "$key" ]] || [[ "$key" == \#* ]]; then
    continue
  fi
  cfg["$key"]="$value"
done < <(grep -E '^[^#]+' "$CONF_FILE" || true)

get_cfg() {
  local k="$1"
  echo "${cfg[$k]:-}"
}

# determine Aeron build dir if present
if [ -d "$ROOT_DIR/../aeron/cppbuild/Release" ]; then
  AERON_BUILD_DIR="$ROOT_DIR/../aeron/cppbuild/Release"
elif [ -d "$ROOT_DIR/../aeron/build" ]; then
  AERON_BUILD_DIR="$ROOT_DIR/../aeron/build"
else
  AERON_BUILD_DIR=""
fi

START_MEDIA_DRIVER=$(get_cfg start.media.driver)
SUB_BG=$(get_cfg subscriber.run.in.bg)
PUB_BG=$(get_cfg publisher.run.in.bg)
PUB_LIMIT=$(get_cfg publisher.msg.limit)
PUB_RATE=$(get_cfg publisher.msg.rate)
PUB_INTERVAL_MS=$(get_cfg publisher.msg.interval.ms)

if [ -z "$PUB_INTERVAL_MS" ] && [ -n "$PUB_RATE" ]; then
  if [[ "$PUB_RATE" =~ ^[0-9]+$ ]] && [ "$PUB_RATE" -gt 0 ]; then
    PUB_INTERVAL_MS=$((1000 / PUB_RATE))
  fi
fi
PUB_INTERVAL_MS=${PUB_INTERVAL_MS:-500}

echo "Aeron build dir: ${AERON_BUILD_DIR:-'(none)'}"


# ensure logs dir (create before starting processes that write logs)
mkdir -p "$ROOT_DIR/logs"

# start media-driver if requested
if [ "$START_MEDIA_DRIVER" = "true" ] && [ -x "$ROOT_DIR/../aeron/aeron-samples/scripts/media-driver" ]; then
  echo "Starting MediaDriver..."
  (cd "$ROOT_DIR/../aeron/aeron-samples/scripts" && nohup ./media-driver > "$ROOT_DIR/logs/media-driver.log" 2>&1 &)
  echo "MediaDriver started (logs: $ROOT_DIR/logs/media-driver.log)"
  sleep 1
fi

# start subscriber
echo "Starting subscriber (bg=${SUB_BG:-false})"
SUB_CMD=("$ROOT_DIR/cpp-subscriber/scripts/run-subscriber.sh" )
if [ -n "$AERON_BUILD_DIR" ]; then
  export AERON_BUILD_DIR
fi

# If the subscriber binary is missing, attempt to build it automatically
if [ ! -x "$ROOT_DIR/cpp-subscriber/build/bin/cpp-subscriber" ]; then
  echo "Subscriber binary not found; attempting to build in $ROOT_DIR/cpp-subscriber/build"
  pushd "$ROOT_DIR/cpp-subscriber" >/dev/null
  mkdir -p build && cd build
  CMAKE_ARGS=(..)
  if [ -n "$AERON_BUILD_DIR" ]; then
    CMAKE_ARGS+=("-DAERON_BUILD_DIR=$AERON_BUILD_DIR")
  fi
  cmake "${CMAKE_ARGS[@]}"
  if ! cmake --build . --target cpp-subscriber -j; then
    echo "Automatic build failed. Please build manually:" >&2
    echo "  cd $ROOT_DIR/cpp-subscriber && mkdir -p build && cd build && cmake .. -DAERON_BUILD_DIR=/path/to/aeron/cppbuild/Release && cmake --build . --target cpp-subscriber -j" >&2
    popd >/dev/null
    exit 1
  fi
  popd >/dev/null
fi

if [ "$SUB_BG" = "true" ]; then
  # Run the subscriber binary directly in background to ensure LD_LIBRARY_PATH is set
  SUB_BIN="$ROOT_DIR/cpp-subscriber/build/bin/cpp-subscriber"
  if [ ! -x "$SUB_BIN" ]; then
    echo "Subscriber binary not found at $SUB_BIN" >&2
    exit 1
  fi
  # Safely prepend Aeron native lib dir if present. Use :- to avoid unbound variable when LD_LIBRARY_PATH is unset.
  export LD_LIBRARY_PATH="${AERON_BUILD_DIR:+${AERON_BUILD_DIR}/lib:}${LD_LIBRARY_PATH:-}"
  nohup "$SUB_BIN" > "$ROOT_DIR/logs/subscriber.log" 2>&1 &
  echo "Subscriber started in background; logs: $ROOT_DIR/logs/subscriber.log"
else
  # start in a new terminal if available, otherwise foreground
  if command -v xterm >/dev/null 2>&1; then
    xterm -e "bash -lc '${SUB_CMD[*]}; read -p \"Press enter to close...\"'" &
  else
    echo "Running subscriber in foreground (use ctrl-C to stop)." >&2
    "${SUB_CMD[@]}"
  fi
fi

# start publisher
echo "Starting publisher (bg=${PUB_BG:-false})"
PUB_CMD=("$ROOT_DIR/java-publisher/scripts/start-publisher.sh")
if [ -n "$PUB_LIMIT" ] && [ "$PUB_LIMIT" != "" ]; then
  if [ "$PUB_LIMIT" = "-1" ]; then
    # loop
    PUB_ARG1="loop"
  else
    PUB_ARG1="$PUB_LIMIT"
  fi
else
  PUB_ARG1="10"
fi
PUB_ARG2="$PUB_INTERVAL_MS"

if [ "$PUB_BG" = "true" ]; then
  "$PUB_CMD" "$PUB_ARG1" "$PUB_ARG2" --bg
  echo "Publisher started in background (logs: $ROOT_DIR/java-publisher/logs/java-publisher.log)"
else
  "$PUB_CMD" "$PUB_ARG1" "$PUB_ARG2"
fi

echo "start_all completed"
