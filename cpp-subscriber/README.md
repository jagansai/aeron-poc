# cpp-subscriber

Scaffold for a C++ Aeron subscriber. This CMake project attempts to find Aeron native artifacts in `AERON_BUILD_DIR` (defaults to `../aeron/build`).

Build and run (example):

```bash
# from repo root
cd cpp-subscriber
mkdir -p build && cd build
cmake .. -DAERON_BUILD_DIR=/home/saijagannath/Documents/code/java_code/aeron/build
cmake --build . --target cpp-subscriber -j
./bin/cpp-subscriber
```

Notes:
- If Aeron native libraries are not yet built, run `./gradlew build` inside your Aeron clone first.
- The source `src/main.cpp` will try to compile against Aeron C++ headers; if headers are not found it falls back to a simple UDP listener for quick testing.
