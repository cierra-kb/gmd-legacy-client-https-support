#!/usr/bin/env bash

if [ ! -v ANDROID_NDK_ROOT ]; then
    echo "The environment variable \`ANDROID_NDK_ROOT\` is not set." \
        "The value should be a path pointing to the NDK's root directory."
    echo "Hint: ANDROID_NDK_ROOT=~/NDK/r16b ./configure.sh"
    exit -1
fi

readonly THIRD_PARTY_SRC_DIR=$(realpath "./.third_party_src")
readonly THIRD_PARTY_ARTIFACTS_DIR=$(realpath "./.artifacts")
readonly THIRD_PARTY_BUILD_DIR=$(realpath "./.third_party_build")

[ -e "$THIRD_PARTY_SRC_DIR" ] || mkdir $THIRD_PARTY_SRC_DIR
[ -e "$THIRD_PARTY_BUILD_DIR" ] || mkdir $THIRD_PARTY_BUILD_DIR
[ -e "$THIRD_PARTY_ARTIFACTS_DIR" ] || mkdir $THIRD_PARTY_ARTIFACTS_DIR

readonly ZLIB_REPO=https://github.com/madler/zlib.git
readonly OPENSSL_REPO=https://github.com/openssl/openssl.git
readonly CURL_REPO=https://github.com/curl/curl.git

readonly ZLIB_COMMIT=51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf
readonly OPENSSL_COMMIT=c0a7890b6244cc5620942c3beeb8683f2164560e
readonly CURL_COMMIT=400fffa90f30c7a2dc762fa33009d24851bd2016

readonly ZLIB_SRC_PATH=$(realpath "$THIRD_PARTY_SRC_DIR/zlib")

readonly OPENSSL_SRC_PATH=$(realpath "$THIRD_PARTY_SRC_DIR/openssl")
readonly OPENSSL_BUILD_PATH=$(realpath "$THIRD_PARTY_BUILD_DIR/openssl")
readonly OPENSSL_ARTIFACTS_PATH=$(realpath "$THIRD_PARTY_ARTIFACTS_DIR/openssl")

readonly CURL_SRC_PATH=$(realpath "$THIRD_PARTY_SRC_DIR/curl")
readonly CURL_BUILD_PATH=$(realpath "$THIRD_PARTY_BUILD_DIR/curl")
readonly CURL_ARTIFACTS_PATH=$(realpath "$THIRD_PARTY_ARTIFACTS_DIR/curl")

PATH=$PATH:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/
PATH=$PATH:$ANDROID_NDK_ROOT/toolchains/x86-4.9/prebuilt/linux-x86_64/bin/

if [ -d $ZLIB_SRC_PATH ]; then
    commit=$(cd $ZLIB_SRC_PATH && git rev-parse HEAD 2>/dev/null)
    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        rm -rf ZLIB_PATH
    elif [[ $commit != $ZLIB_COMMIT ]]; then
        cd $ZLIB_SRC_PATH && git checkout $ZLIB_COMMIT || rm -rf $ZLIB_SRC_PATH
    fi
fi

if [ ! -e $ZLIB_SRC_PATH ]; then
    $(git clone $ZLIB_REPO $ZLIB_SRC_PATH && \
        cd $ZLIB_SRC_PATH && \
        git checkout $ZLIB_COMMIT) || exit -1
fi

if [ ! -e "$THIRD_PARTY_ARTIFACTS_DIR/arm/zlib/lib" ]; then
    build_dir="$THIRD_PARTY_BUILD_DIR/zlib/arm"
    artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/arm/zlib"

    mkdir -p "$THIRD_PARTY_ARTIFACTS_DIR/arm"

    cd $ZLIB_SRC_PATH && \
        cmake -B$build_dir \
            -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake \
            -DANDROID_ABI=armeabi-v7a \
            -DANDROID_TOOLCHAIN=gcc \
            -DANDROID_API_LEVEL=16 \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=$artifact_dir && \
        cmake \
            --build $build_dir \
            --config Release && \
        cmake \
            --install $build_dir \
            --prefix $artifact_dir
    cd $artifact_dir && \
        stat include/zlib.h>/dev/null && \
        mv include/zlib.h include/zlib_custom.h
fi

if [ ! -e "$THIRD_PARTY_ARTIFACTS_DIR/x86/zlib/lib" ]; then
    build_dir="$THIRD_PARTY_BUILD_DIR/zlib/x86"
    artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/x86/zlib"

    mkdir -p "$THIRD_PARTY_ARTIFACTS_DIR/x86"

    cd $ZLIB_SRC_PATH && \
        cmake -B$build_dir \
            -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake \
            -DANDROID_ABI=x86 \
            -DANDROID_TOOLCHAIN=gcc \
            -DANDROID_API_LEVEL=16 \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=$artifact_dir && \
        cmake \
            --build $build_dir \
            --config Release && \
        cmake \
            --install $build_dir \
            --prefix $artifact_dir
    cd $artifact_dir && \
        stat include/zlib.h>/dev/null && \
        mv include/zlib.h include/zlib_custom.h
fi

# OPENSSL

if [ -d $OPENSSL_SRC_PATH ]; then
    commit=$(cd $OPENSSL_SRC_PATH && git rev-parse HEAD 2>/dev/null)
    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        rm -rf OPENSSL_PATH
    elif [[ $commit != $OPENSSL_COMMIT ]]; then
        cd $OPENSSL_SRC_PATH && git checkout $OPENSSL_COMMIT || rm -rf $OPENSSL_SRC_PATH
    fi
fi
if [ ! -e $OPENSSL_SRC_PATH ]; then
    $(git clone $OPENSSL_REPO $OPENSSL_SRC_PATH --recursive || \
        cd $OPENSSL_SRC_PATH && \
        git checkout $OPENSSL_COMMIT)
    cd $OPENSSL_SRC_PATH && grep -rlxZ ".rodata" crypto/ | xargs -0 sed -i 's/.rodata/.section .rodata/g' 2>/dev/null
    cd $OPENSSL_SRC_PATH && grep -rlZ "zlib.h" crypto/ | xargs -0 sed -i 's/zlib.h/zlib_custom.h/g' 2>/dev/null
    cd $OPENSSL_SRC_PATH && grep -rlZ "asm (\"" include/crypto/modes.h crypto/bn/bn_div.c | xargs -0 sed -i 's/asm (\"/__asm__ (\"/g' 2>/dev/null
    cd $OPENSSL_SRC_PATH && grep -rlZ "asm volatile(" crypto/bn/bn_div.c | xargs -0 sed -i 's/asm volatile(/__asm__ volatile(/g' 2>/dev/null
fi

if [ ! -e "$THIRD_PARTY_ARTIFACTS_DIR/arm/openssl/lib" ]; then
    build_dir="$THIRD_PARTY_BUILD_DIR/openssl/arm"
    artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/arm/openssl"

    mkdir -p "$THIRD_PARTY_ARTIFACTS_DIR/arm"
    mkdir -p "$build_dir"

    cp -r $OPENSSL_SRC_PATH/** "$build_dir"

    cd $build_dir && \
        CFLAGS=-std=c99 ./Configure android-arm no-apps no-docs -D__ANDROID_API__=16 --prefix=$artifact_dir && \
        make && \
        make install
fi

if [ ! -e "$THIRD_PARTY_ARTIFACTS_DIR/x86/openssl/lib" ]; then
    build_dir="$THIRD_PARTY_BUILD_DIR/openssl/x86"
    artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/x86/openssl"

    mkdir -p "$THIRD_PARTY_ARTIFACTS_DIR/x86"
    mkdir -p "$build_dir"

    cp -r $OPENSSL_SRC_PATH/** "$build_dir"

    cd $build_dir && \
        CFLAGS=-std=c99 ./Configure android-x86 no-apps no-docs -D__ANDROID_API__=16 --prefix=$artifact_dir && \
        make && \
        make install
fi

# CURL

if [ -d $CURL_SRC_PATH ]; then
    commit=$(cd $CURL_SRC_PATH && git rev-parse HEAD 2>/dev/null)
    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        rm -rf CURL_PATH
    elif [[ $commit != $CURL_COMMIT ]]; then
        cd $CURL_SRC_PATH && git checkout $CURL_COMMIT || rm -rf $CURL_SRC_PATH
    fi
fi
if [ ! -e $CURL_SRC_PATH ]; then
    $(git clone $CURL_REPO $CURL_SRC_PATH && \
        cd $CURL_SRC_PATH && \
        git checkout $CURL_COMMIT) || exit -1
    cd $CURL_SRC_PATH && grep -rlxZ "#include <zlib.h>" | xargs -0 sed -i 's/zlib.h/zlib_custom.h/g' 2>/dev/null
    cd $CURL_SRC_PATH && grep -rlxZ "#define CURL_SIMPLE_LOCK_INIT 0" | xargs -0 sed -i 's/CURL_SIMPLE_LOCK_INIT 0/CURL_SIMPLE_LOCK_INIT {0}/g'
fi

if [ ! -e "$THIRD_PARTY_ARTIFACTS_DIR/arm/curl/lib" ]; then
    build_dir="$THIRD_PARTY_BUILD_DIR/curl/arm"
    artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/arm/curl"
    openssl_artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/arm/openssl"
    zlib_artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/arm/zlib"

    mkdir -p "$THIRD_PARTY_ARTIFACTS_DIR/arm"
    mkdir -p "$build_dir"

    cp -r $CURL_SRC_PATH/** "$build_dir"

    cd $build_dir && \
        autoreconf -fi && \
        LIBS="-lssl -lcrypto -latomic" \
        LDFLAGS="-L$openssl_artifact_dir/lib -L$zlib_artifact_dir/lib" \
        CFLAGS="--sysroot=$ANDROID_NDK_ROOT/platforms/android-16/arch-arm/" \
        CPPFLAGS="-I$openssl_artifact_dir/include \
                -I$zlib_artifact_dir/include \
                -I$ANDROID_NDK_ROOT/sysroot/usr/include \
                -I$ANDROID_NDK_ROOT/sysroot/usr/include/arm-linux-androideabi \
                -D__ANDROID_API__=16" \
        ./configure \
            --host arm-linux-androideabi \
            --target arm-linux-androideabi \
            --with-zlib \
            --with-openssl \
            --without-libpsl \
            --with-pic \
            --prefix=$artifact_dir && \
        make && \
        make install
fi

if [ ! -e "$THIRD_PARTY_ARTIFACTS_DIR/x86/curl/lib" ]; then
    build_dir="$THIRD_PARTY_BUILD_DIR/curl/x86"
    artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/x86/curl"
    openssl_artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/x86/openssl"
    zlib_artifact_dir="$THIRD_PARTY_ARTIFACTS_DIR/x86/zlib"

    mkdir -p "$THIRD_PARTY_ARTIFACTS_DIR/x86"
    mkdir -p "$build_dir"

    cp -r $CURL_SRC_PATH/** "$build_dir"

    PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/:$PATH

    cd $build_dir && \
        autoreconf -fi && \
        LIBS="-l$openssl_artifact_dir/lib/libssl.so -l$openssl_artifact_dir/lib/libcrypto.so -l$openssl_artifact_dir/lib/ossl-modules/legacy.so -latomic" \
        LDFLAGS="-L$openssl_artifact_dir/lib -L$zlib_artifact_dir/lib" \
        CFLAGS="--sysroot=$ANDROID_NDK_ROOT/platforms/android-16/arch-x86/" \
        CPPFLAGS="-I$openssl_artifact_dir/include \
                -I$zlib_artifact_dir/include \
                -I$ANDROID_NDK_ROOT/sysroot/usr/include \
                -I$ANDROID_NDK_ROOT/sysroot/usr/include/i686-linux-android \
                -D__ANDROID_API__=16" \
        ./configure \
            --host i686-linux-android \
            --target i686-linux-android \
            --with-zlib \
            --with-openssl \
            --without-libpsl \
            --with-pic \
            --prefix=$artifact_dir && \
        make && \
        make install
fi
