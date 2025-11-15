# Aeron POC — Java Publisher (Gradle) + C++ Subscriber (CMake) — Linux-only

This repository contains a minimal proof-of-concept plan to demonstrate cross-language interoperability using Aeron: a Java publisher (Gradle) and a C++ subscriber (CMake) communicating over UDP loopback to an external MediaDriver on Linux.

---

## Goals
- Prove Aeron interoperability between a Java publisher and a C++ subscriber.
- Keep the environment simple on Linux: external MediaDriver process, UDP loopback channel, single stream id.

## Channel & Stream
- Channel URI: `aeron:udp?endpoint=127.0.0.1:40123`
- Stream ID: `1001`
- Use these same values in both Java and C++ clients.

## Prerequisites (Ubuntu / Debian example)
- Git
- OpenJDK 21+ (`openjdk-21-jdk`)
- Gradle (or use Gradle Wrapper in project)
- CMake (3.15+), make, `build-essential` (gcc, g++)
- Python (optional for build scripts)

Example install on Ubuntu:

```bash
sudo apt update
sudo apt install -y git openjdk-21-jdk gradle cmake build-essential python3
```

If you prefer Gradle Wrapper for the Java project, ensure wrapper files are present or use system `gradle`.

## Recommended Aeron Version
- Use a stable recent Aeron release (for example, 1.49.x or latest). Confirm Java client compatibility with JDK 21.
- You will need to clone the Aeron repo or install the MediaDriver binary/script from the Aeron project to run the driver.

## Running an external MediaDriver (Linux)
Clone Aeron (if you haven't already) and run the provided media-driver script used by samples:

```bash
git clone https://github.com/aeron-io/aeron.git
cd aeron/aeron-samples/scripts
./media-driver
```

Leave the MediaDriver running in its terminal. It listens on the default socket directories and ports; using the channel above will route traffic via UDP loopback.

## Project layout (expected)
- `java-publisher/` — Gradle project containing the Java publisher
  - `build.gradle` or `gradle` wrapper
  - `src/main/java/.../Publisher.java`

- `cpp-subscriber/` — C++ project using CMake for the subscriber
  - `CMakeLists.txt`
  - `src/main.cpp`

- `README.md` — this file


## Build & Run (Linux)

1) Start MediaDriver (in a separate terminal):

```bash
# from the cloned aeron repo
cd aeron/aeron-samples/scripts
./media-driver
```

2) Java publisher (Gradle):

If you have a `java-publisher` Gradle project (recommended to include Gradle wrapper):

```bash
# from repo root
cd java-publisher
./gradlew build       # or `gradle build` if not using wrapper
# run the publisher app (adjust main class as implemented)
./gradlew run -q
# or, directly run the jar if the build produces an executable jar
java -jar build/libs/java-publisher-all.jar
```

Suggested Gradle dependency snippet to add to `build.gradle`:

```groovy
dependencies {
    implementation 'io.aeron:aeron-client:1.49.0' // pick the Aeron version you want
}
```

3) C++ subscriber (CMake):

```bash
cd cpp-subscriber
mkdir -p build && cd build
cmake ..
make -j$(nproc)
# run the subscriber
./cpp-subscriber
```

The subscriber should print received messages to stdout as the publisher sends them.

## Expected minimal workflow
1. Start `media-driver` in terminal A.
2. Start the C++ subscriber in terminal B (it will wait and poll for messages).
3. Run the Java publisher in terminal C. Publisher will publish messages to the configured channel/stream and the C++ subscriber should receive them and print to its terminal.

## Troubleshooting
- UDP loopback and firewall: on Linux loopback is normally unrestricted. If messages are not received, ensure the `endpoint` port (40123) is not in use and that both apps use the exact same channel and stream id.
- MediaDriver not found: clone `aeron` repo and run `aeron-samples/scripts/media-driver` as shown above.
- Aeron version mismatch: ensure both Java and C++ clients target a compatible Aeron protocol/version.
- If building C++ fails due to missing Aeron headers/libs, consider building Aeron native artifacts from the Aeron repo or using WSL2/linux to match build tools.

---

## Notes
- This README assumes you will run and test on Linux (native or WSL2). Windows-specific instructions are intentionally omitted.
- Keep the MediaDriver external for clear separation between publisher and subscriber.

---