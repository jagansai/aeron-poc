

# if argument is passed for AERON_BUILD_DIR, use it
if [ $# -ge 1 ]; then
  AERON_BUILD_DIR="$1"
else
  AERON_BUILD_DIR="/home/saijagannath/Documents/code/java_code/aeron/cppbuild/Release/"
fi
echo "Using AERON_BUILD_DIR: $AERON_BUILD_DIR"

cmake -DAERON_BUILD_DIR="$AERON_BUILD_DIR" -B build

cmake --build build --target cpp-subscriber -j
if [ $? -ne 0 ]; then
  echo "Build failed"
  exit 1
fi

echo "Build succeeded; binary at ./build/bin/cpp-subscriber"

# if 2nd arg is run, execute the subscriber after build
if [ $# -ge 2 ] && [ "$2" = "run" ]; then
  export LD_LIBRARY_PATH="${AERON_BUILD_DIR}/lib:${LD_LIBRARY_PATH:-}"
  exec ./build/bin/cpp-subscriber
fi


