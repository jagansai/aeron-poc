#!/usr/bin/env bash
set -euo pipefail

# Usage: ./start-publisher.sh [loop|<count>] [interval-ms] [--bg]
# Examples:
#  ./start-publisher.sh         # sends 10 messages (default)
#  ./start-publisher.sh 100 200 # send 100 messages with 200ms interval
#  ./start-publisher.sh loop    # run continuously
#  ./start-publisher.sh loop 100 --bg # run continuously, background

ROOT_DIR="$(dirname "$(dirname "$0")")"
JAR="$ROOT_DIR/build/libs/java-publisher.jar"

COUNT_ARG="10"
INTERVAL_ARG="500"
BG=false

if [ $# -ge 1 ]; then
  COUNT_ARG="$1"
fi
if [ $# -ge 2 ]; then
  INTERVAL_ARG="$2"
fi
if [ $# -ge 3 ] && [ "$3" = "--bg" ]; then
  BG=true
fi

if [ ! -f "$JAR" ]; then
  echo "Jar not found; building..."
  (cd "$ROOT_DIR" && gradle build)
fi

JAVA_FLAGS=("--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED" "--add-opens=java.base/java.util.zip=ALL-UNNAMED")

CMD=(java "${JAVA_FLAGS[@]}" -jar "$JAR" "$COUNT_ARG" "$INTERVAL_ARG")

if [ "$BG" = true ]; then
  mkdir -p "$ROOT_DIR/logs"
  nohup "${CMD[@]}" > "$ROOT_DIR/logs/java-publisher.log" 2>&1 &
  echo "Publisher started in background; logs: $ROOT_DIR/logs/java-publisher.log"
else
  exec "${CMD[@]}"
fi
