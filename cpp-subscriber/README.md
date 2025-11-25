# cpp-subscriber

A C++ Aeron subscriber using CMake. Works on Windows (MSVC) and Linux (GCC/Clang).

## Prerequisites

1. **Aeron** - Clone and build Aeron native artifacts
2. **CMake** 3.18+
3. **C++17 compiler** - MSVC (Windows) or GCC/Clang (Linux)

## Environment Variables

Set these environment variables for VS Code IntelliSense and builds:

| Variable | Description | Example (Windows) | Example (Linux) |
|----------|-------------|-------------------|-----------------|
| `AERON_SRC_DIR` | Aeron source directory | `D:\code\aeron` | `/home/user/aeron` |
| `AERON_BUILD_DIR` | Aeron build output | `D:\code\aeron\cppbuild\Release` | `/home/user/aeron/cppbuild/Release` |

### Windows (PowerShell)

```powershell
# Set for current session
$env:AERON_SRC_DIR = "D:\code\aeron"
$env:AERON_BUILD_DIR = "D:\code\aeron\cppbuild\Release"

# Set permanently (user-level)
[Environment]::SetEnvironmentVariable("AERON_SRC_DIR", "D:\code\aeron", "User")
[Environment]::SetEnvironmentVariable("AERON_BUILD_DIR", "D:\code\aeron\cppbuild\Release", "User")
```

### Linux (bash)

```bash
# Add to ~/.bashrc or ~/.profile
export AERON_SRC_DIR="$HOME/aeron"
export AERON_BUILD_DIR="$HOME/aeron/cppbuild/Release"
```

## Build

```bash
# From repo root
mkdir -p build && cd build

# Configure (uses environment variables, or pass explicitly)
cmake .. -DAERON_BUILD_DIR=$AERON_BUILD_DIR -DAERON_SRC_DIR=$AERON_SRC_DIR

# Build
cmake --build . --config Release

# Run
./bin/Release/cpp-subscriber   # Windows
./bin/cpp-subscriber           # Linux
```

## VS Code Setup

1. Set the environment variables above
2. Restart VS Code (so it picks up the env vars)
3. Open the project folder
4. Select the appropriate configuration:
   - `Ctrl+Shift+P` → "C/C++: Select a Configuration"
   - Choose `Windows-MSVC`, `Linux-GCC`, or `Linux-Clang`

## Notes

- Build Aeron first: `./gradlew` (Java) then `cppbuild/cppbuild` (native)
- The C++ API deprecation warning is expected - Aeron plans to replace it in v1.50.0
