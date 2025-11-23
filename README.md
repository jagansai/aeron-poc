```markdown
# Aeron POC — Java Publisher (Gradle) + C++ Subscriber (CMake) — Linux

This repository is a small proof-of-concept demonstrating cross-language interoperability with Aeron: a Java publisher and a C++ subscriber communicating over UDP loopback via an external MediaDriver.

Channel & stream
- Channel: `aeron:udp?endpoint=127.0.0.1:40123`
- Stream ID: `1001`

Repository highlights
- `java-publisher/` — Java publisher (Gradle)
  - `scripts/start-publisher.sh` — helper to build/run the publisher (supports background mode and simple args)

- `cpp-subscriber/` — C++ subscriber (CMake)
  - `scripts/run-subscriber.sh` — helper to run the subscriber (sets `LD_LIBRARY_PATH`)

- `scripts/start_all.sh` — top-level helper that reads `scripts/run.conf` and can start MediaDriver, subscriber and publisher together (or individually via their helpers)

Prerequisites (Ubuntu/Debian example)
- Git, OpenJDK 21+, Gradle (or use the wrapper under `java-publisher`), CMake, `build-essential`.

Install example:
```bash
sudo apt update
sudo apt install -y git openjdk-21-jdk gradle cmake build-essential
```

MediaDriver
```bash
git clone https://github.com/aeron-io/aeron.git
cd aeron/aeron-samples/scripts
./media-driver
```

Quickstart (recommended)
1. Ensure MediaDriver is running (see commands above) or set `start.media.driver=true` in `scripts/run.conf` and let `start_all.sh` attempt to start it.
2. Edit `scripts/run.conf` to configure background/foreground and publisher interval. Example `scripts/run.conf`:

```properties
subscriber.run.in.bg=true
publisher.run.in.bg=true
publisher.msg.limit=2000
publisher.msg.interval.ms=500
start.media.driver=true
```

3. Start everything using the start_all.sh:

```bash
./scripts/start_all.sh ./scripts/run.conf
```

What the script does
- Optionally starts MediaDriver (if `start.media.driver=true` and `aeron` repo is present),
- Builds the C++ subscriber if missing and starts it (foreground/background),
- Runs the Java publisher (foreground/background) using the configured interval.

Run components individually
- Java publisher (helper):
```bash
java-publisher/scripts/start-publisher.sh <count|loop> <interval-ms> [--bg]
# examples:
java-publisher/scripts/start-publisher.sh 100 200   # send 100 messages, 200ms interval
java-publisher/scripts/start-publisher.sh loop 500  # run continuously, 500ms between messages
```

- C++ subscriber (build & run):
```bash
cd cpp-subscriber
mkdir -p build && cd build
cmake .. -DAERON_BUILD_DIR=/path/to/aeron/cppbuild/Release
cmake --build . --target cpp-subscriber -j
../scripts/run-subscriber.sh
```

Logs
- `scripts/start_all.sh` creates `logs/` and writes `media-driver.log`, `subscriber.log`, and the publisher log when run in background.

Notes & troubleshooting
- If the C++ build cannot find Aeron headers/libs, build Aeron native artifacts so `cppbuild/Release` contains `include/` and `lib/`.
- If scripts complain about `LD_LIBRARY_PATH`, use the provided `scripts/*` helpers; they set the environment correctly.
```
