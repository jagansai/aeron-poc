cmake_minimum_required(VERSION 3.18)
project(cpp-subscriber LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

# Point to Aeron build outputs. Override with -DAERON_BUILD_DIR=/path/to/aeron/build
if (NOT DEFINED AERON_BUILD_DIR)
    set(AERON_BUILD_DIR "${CMAKE_SOURCE_DIR}/../aeron/build" CACHE PATH "Aeron build directory (cppbuild/<config>)")
endif()

if (NOT DEFINED AERON_SRC_DIR)
    set(AERON_SRC_DIR "${CMAKE_SOURCE_DIR}/../aeron" CACHE PATH "Aeron source directory")
endif()

message(STATUS "Using AERON_BUILD_DIR=${AERON_BUILD_DIR}")
message(STATUS "Using AERON_SRC_DIR=${AERON_SRC_DIR}")

# Check for headers - either in build/include (installed) or source tree
if (EXISTS "${AERON_BUILD_DIR}/include")
    # Headers installed to build directory
    set(AERON_INCLUDE_DIRS
        "${AERON_BUILD_DIR}/include"
        "${AERON_BUILD_DIR}/generated"
        "${AERON_BUILD_DIR}/_deps/hdr_histogram-build/include"
    )
elseif (EXISTS "${AERON_SRC_DIR}/aeron-client/src/main/cpp")
    # Use headers from source tree
    set(AERON_INCLUDE_DIRS
        "${AERON_SRC_DIR}/aeron-client/src/main/cpp"
        "${AERON_BUILD_DIR}/generated"
        "${AERON_BUILD_DIR}/_deps/hdr_histogram-build/include"
    )
    message(STATUS "Using Aeron headers from source tree: ${AERON_SRC_DIR}/aeron-client/src/main/cpp")
else()
    message(FATAL_ERROR "Cannot find Aeron headers. Check AERON_BUILD_DIR (${AERON_BUILD_DIR}) or AERON_SRC_DIR (${AERON_SRC_DIR}).")
endif()

add_executable(cpp-subscriber src/main.cpp)

target_include_directories(cpp-subscriber PRIVATE ${AERON_INCLUDE_DIRS})

target_link_directories(cpp-subscriber PRIVATE "${AERON_BUILD_DIR}/lib")

# Try shared client library first, then static
set(AERON_LIB_NAMES aeron_client_shared aeron_client)
find_library(AERON_CLIENT_LIB
    NAMES ${AERON_LIB_NAMES}
    HINTS "${AERON_BUILD_DIR}/lib"
    PATH_SUFFIXES release debug
)

if (NOT AERON_CLIENT_LIB)
    message(FATAL_ERROR "Cannot find Aeron client library in ${AERON_BUILD_DIR}/lib. Ensure Aeron native artifacts are built (cppbuild/<config>) and AERON_BUILD_DIR points to the directory containing lib/.")
endif()

# Check if we're using the shared library and add the required definition
get_filename_component(AERON_LIB_NAME ${AERON_CLIENT_LIB} NAME_WE)
if (AERON_LIB_NAME MATCHES "shared" OR MSVC)
    # CRITICAL: Must define CLIENT_SHARED when using aeron_client_shared on Windows/MSVC
    # This ensures proper DLL import/export declarations
    target_compile_definitions(cpp-subscriber PRIVATE CLIENT_SHARED)
    message(STATUS "Using shared Aeron client library - CLIENT_SHARED defined")
endif()

target_link_libraries(cpp-subscriber PRIVATE ${AERON_CLIENT_LIB})

if (WIN32)
    target_link_libraries(cpp-subscriber PRIVATE ws2_32)
    target_compile_definitions(cpp-subscriber PRIVATE _WIN32_WINNT=0x0A00)
endif()

set_target_properties(cpp-subscriber PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
