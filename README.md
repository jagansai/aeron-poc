# Aeron POC — Java Publisher (Gradle) + C++ Subscriber (CMake)

This repository demonstrates Aeron interoperability between a Java publisher and a C++ subscriber communicating over UDP loopback through an external MediaDriver. The PoC can be built and run on both Linux and Windows.

## Channel & stream
- Channel URI: `aeron:udp?endpoint=127.0.0.1:40123`
- Stream ID: `1001`

## Prerequisites
### Linux (Ubuntu/Debian example)
- Git
- OpenJDK 17+ (`openjdk-17-jdk`)
- Gradle (or use the wrapper under `java-publisher`)
- CMake 3.18+, `build-essential` (gcc/g++)
- Aeron repository clone nearby (for `media-driver` and native C++ artifacts)

```bash
sudo apt update
sudo apt install -y git openjdk-17-jdk gradle cmake build-essential
```

### Windows (PowerShell)
- Git
- OpenJDK 17+ (Temurin/Adoptium recommended)
- Visual Studio 2022+ with “Desktop development with C++”
- CMake 3.18+
- Aeron repository clone so you can run `aeron-samples\scripts\media-driver.cmd` and point the C++ build to `cppbuild/Release`

## MediaDriver
### Linux
```bash
git clone https://github.com/aeron-io/aeron.git
cd aeron/aeron-samples/scripts
./media-driver
```

### Windows
```powershell
cd C:\path\to\aeron\aeron-samples\scripts
.\media-driver.cmd
```

Keep the MediaDriver running while you start the subscriber and publisher.

## Java publisher
`java-publisher` is a Gradle project (depends on `io.aeron:aeron-client:1.49.0`). The helper `java-publisher/scripts/start-publisher.sh` builds the jar and supports background execution on Linux; on Windows you can call the Gradle wrapper (`gradlew.bat`).

```bash
cd java-publisher
./gradlew build
./gradlew startPublisher --args="100 200"
```

`startPublisher` accepts `<count|loop>` and `<interval-ms>` arguments.

## C++ subscriber
### Linux
```bash
cd cpp-subscriber
mkdir -p build && cd build
cmake .. -DAERON_BUILD_DIR=/path/to/aeron/cppbuild/Release
cmake --build . --target cpp-subscriber -j
../scripts/run-subscriber.sh
```
`run-subscriber.sh` sets `LD_LIBRARY_PATH` to include the Aeron `lib/` directory.

### Windows
```powershell
cd cpp-subscriber
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -DAERON_BUILD_DIR=C:/path/to/aeron/cppbuild/Release
cmake --build . --config Release --target cpp-subscriber
..\scripts\run-subscriber.ps1 -BuildDir build
```
`run-subscriber.ps1` prepends the Aeron native `lib/` folder to `PATH` before launching the executable.

### Notes
- The CMake script links `ws2_32` on Windows and accepts `AERON_BUILD_DIR` from both platforms.

## Helper scripts
- `scripts/start_all.sh` (Linux): reads `scripts/run.conf`, optionally starts MediaDriver, builds the subscriber, and launches both components (supports background logging).
- `scripts/start_all.ps1` (Windows): PowerShell orchestrator that parses `run.conf`, starts `media-driver.cmd`, builds the subscriber via CMake, and runs the subscriber/publisher (background logging supported).
- `cpp-subscriber/scripts/run-subscriber.sh`/`.ps1`: platform-specific helpers that ensure Aeron native libs are on the loader path before running the subscriber executable.
- `java-publisher/scripts/start-publisher.sh`: cross-platform helper that wraps the Gradle task (on Windows you can also call `gradlew.bat startPublisher --args="..."`).

## Configuration (`scripts/run.conf`)
```properties
subscriber.run.in.bg=true
publisher.run.in.bg=true
publisher.msg.limit=2000
publisher.msg.interval.ms=20
start.media.driver=true
```
- `subscriber.run.in.bg` / `publisher.run.in.bg`: run the component in the background (logs saved to `logs/`).
- `publisher.msg.limit`: number of messages to send (`-1` means loop).
- `publisher.msg.interval.ms`: delay between messages in milliseconds.
- `start.media.driver`: whether the orchestrator tries to start MediaDriver.
- `cmake.generator` (optional): e.g., `Visual Studio 17 2022`; the Windows script respects this value.
- `aeron.build.dir` (optional): absolute path to the Aeron native build output used by the Windows orchestrator.

## Logs
When helper scripts run components in the background they write `media-driver.log`, `subscriber.log`, and `java-publisher.log` under `logs/`. Tail these logs to confirm message flow.
