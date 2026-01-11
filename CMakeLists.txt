cmake_minimum_required(VERSION 3.12)

set(ANDROID_TOOLCHAIN gcc)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(ENABLE_LOGS "Enable logging" OFF)
option(CHECK_SERVER_SUPPORT "Check if the server accepts HTTPS connections at runtime" OFF)
option(ALLOW_INSECURE_CONNECTIONS "Fallback to the original URL if the server does not support HTTPS" OFF)

if(ENABLE_LOGS)
    add_definitions(-DENABLE_LOGS)
endif()

if (CHECK_SERVER_SUPPORT)
    add_definitions(-DCHECK_FOR_HTTPS_SUPPORT)
endif()

if (ALLOW_INSECURE_CONNECTIONS)
    add_definitions(-DALLOW_INSECURE_CONNECTIONS)
endif()

project(secnet VERSION 0.1.0)

if("${ANDROID_ABI}" STREQUAL "armeabi" OR "${ANDROID_ABI}" STREQUAL "armeabi-v7a")
    set(ARTIFACT_ARCH arm)
elseif("${ANDROID_ABI}" STREQUAL "x86")
    set(ARTIFACT_ARCH x86)
else()
    message(FATAL "Cannot determine ARTIFACT_ARCH")
endif()

add_library(libz_shared SHARED IMPORTED)
set_property(TARGET libz_shared PROPERTY
    IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/zlib/lib/libz.so)
target_include_directories(libz_shared INTERFACE ${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/zlib/include)

install(IMPORTED_RUNTIME_ARTIFACTS libz_shared)
file(GLOB ZLIB_HEADER_FILES "${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/zlib/include/*")
install(FILES ${ZLIB_HEADER_FILES} DESTINATION include)


add_library(libssl_shared SHARED IMPORTED)
set_property(TARGET libssl_shared PROPERTY
    IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/openssl/lib/libssl.so)
install(IMPORTED_RUNTIME_ARTIFACTS libssl_shared)

add_library(libcrypto_shared SHARED IMPORTED)
set_property(TARGET libcrypto_shared PROPERTY
    IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/openssl/lib/libcrypto.so)
install(IMPORTED_RUNTIME_ARTIFACTS libcrypto_shared)

add_library(openssl_shared INTERFACE IMPORTED)
target_link_libraries(openssl_shared INTERFACE libssl_shared libcrypto_shared)
target_include_directories(openssl_shared INTERFACE ${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/openssl/include)

file(GLOB OPENSSL_HEADER_FILES "${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/openssl/include/openssl/*")
install(FILES ${OPENSSL_HEADER_FILES} DESTINATION include/openssl)


add_library(libcurl_shared SHARED IMPORTED)
set_property(TARGET libcurl_shared PROPERTY
    IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/curl/lib/libcurl.so)
target_include_directories(libcurl_shared INTERFACE ${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/curl/include)
target_link_libraries(libcurl_shared INTERFACE openssl_shared libz_shared)

install(IMPORTED_RUNTIME_ARTIFACTS libcurl_shared)
file(GLOB CURL_HEADER_FILES "${CMAKE_CURRENT_LIST_DIR}/.artifacts/${ARTIFACT_ARCH}/curl/include/curl/*")
install(FILES ${CURL_HEADER_FILES} DESTINATION include/curl)

include(FetchContent)
FetchContent_Declare(dobby
    GIT_REPOSITORY https://github.com/jmpews/Dobby.git
    GIT_TAG 16b99a55dc219114832c33f3258f48ca2958ed70)
FetchContent_MakeAvailable(dobby)
install(IMPORTED_RUNTIME_ARTIFACTS dobby)

add_library(secnet SHARED src/entry.c)
set_target_properties(secnet PROPERTIES C_STANDARD 99 C_STANDARD_REQUIRED TRUE)
target_link_libraries(secnet PRIVATE libcurl_shared dobby)

install(TARGETS secnet)
