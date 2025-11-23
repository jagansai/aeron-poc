cmake_minimum_required(VERSION 3.15)
project(cpp-subscriber LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

# Point to Aeron build outputs. Override with -DAERON_BUILD_DIR=/path/to/aeron/build
if (NOT DEFINED AERON_BUILD_DIR)
    set(AERON_BUILD_DIR "${CMAKE_SOURCE_DIR}/../aeron/build" CACHE PATH "Aeron build directory (cppbuild/Release)")
endif()

if (NOT DEFINED AERON_SRC_DIR)
    set(AERON_SRC_DIR "${CMAKE_SOURCE_DIR}/../aeron" CACHE PATH "Aeron source directory")
endif()

message(STATUS "Using AERON_BUILD_DIR=${AERON_BUILD_DIR}")
message(STATUS "Using AERON_SRC_DIR=${AERON_SRC_DIR}")

# Require Aeron native build outputs. Do not fall back to source headers.
if (EXISTS "${AERON_BUILD_DIR}/include")
    include_directories(${AERON_BUILD_DIR}/include)
    if (EXISTS "${AERON_BUILD_DIR}/include/aeron")
        include_directories(${AERON_BUILD_DIR}/include/aeron)
    endif()
    if (EXISTS "${AERON_BUILD_DIR}/generated")
        include_directories(${AERON_BUILD_DIR}/generated)
    endif()
    if (EXISTS "${AERON_BUILD_DIR}/_deps/hdr_histogram-build/include")
        include_directories(${AERON_BUILD_DIR}/_deps/hdr_histogram-build/include)
    endif()
else()
    message(FATAL_ERROR "AERON_BUILD_DIR (${AERON_BUILD_DIR}) does not contain include/ — build Aeron native artifacts and set -DAERON_BUILD_DIR to cppbuild/Release")
endif()

link_directories(${AERON_BUILD_DIR}/lib)

# Try to find the shared client library first, then static archive
find_library(AERON_CLIENT_LIB aeron_client_shared HINTS ${AERON_BUILD_DIR}/lib)
if (NOT AERON_CLIENT_LIB)
    find_library(AERON_CLIENT_LIB aeron_client HINTS ${AERON_BUILD_DIR}/lib)
endif()

if (NOT AERON_CLIENT_LIB)
    message(WARNING "Could not find aeron client library in ${AERON_BUILD_DIR}/lib. You may need to adjust AERON_BUILD_DIR or build Aeron native artifacts.")
endif()

add_executable(cpp-subscriber src/main.cpp)

if (AERON_CLIENT_LIB)
    target_link_libraries(cpp-subscriber ${AERON_CLIENT_LIB})
endif()

set_target_properties(cpp-subscriber PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
