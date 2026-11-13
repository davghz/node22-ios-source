#!/usr/bin/env bash
# Build the pinned current stable Node.js release for rootless iOS 15.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION=26.13.1
SHA256=a7f6204ff63b6a2cd274d48903285abb86ed53a99070e532d4c2fd787457d9e6
WORK="${NODE26_WORK:-$ROOT/ios/work}"
SOURCE="${NODE26_SOURCE:-$WORK/node-v$VERSION}"
JOBS="${JOBS:-2}"
mkdir -p "$WORK"
if [ ! -d "$SOURCE" ]; then
    ARCHIVE="$WORK/node-v$VERSION.tar.xz"
    curl -fsSL "https://nodejs.org/dist/v$VERSION/node-v$VERSION.tar.xz" -o "$ARCHIVE"
    ACTUAL="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
    [ "$ACTUAL" = "$SHA256" ] || { echo 'Node source checksum mismatch' >&2; exit 1; }
    mkdir -p "$SOURCE"
    tar -xf "$ARCHIVE" --strip-components=1 -C "$SOURCE"
fi
python3 - "$SOURCE/src/node_version.h" <<'PY'
import pathlib, re, sys
header = pathlib.Path(sys.argv[1]).read_text()
version = '.'.join(re.search(r'#define NODE_' + key + r'_VERSION\s+(\d+)', header).group(1)
                   for key in ('MAJOR', 'MINOR', 'PATCH'))
if version != '26.13.1':
    raise SystemExit('Expected Node.js 26.13.1 source, found ' + version)
PY
PATCH="$ROOT/ios/patches/node26-ios.patch"
PATCH_ID="$(shasum -a 256 "$PATCH" | awk '{print $1}')"
if [ -f "$SOURCE/.rootless-ios-patched" ]; then
    [ "$(cat "$SOURCE/.rootless-ios-patched")" = "$PATCH_ID" ] || {
        echo 'The iOS patch changed; select a clean NODE26_SOURCE directory.' >&2
        exit 1
    }
else
    patch -d "$SOURCE" -p1 --batch < "$PATCH"
    printf '%s\n' "$PATCH_ID" > "$SOURCE/.rootless-ios-patched"
fi

export RUSTUP_TOOLCHAIN="${RUSTUP_TOOLCHAIN:-1.95.0}"
RUST_SYSROOT="$(rustup run "$RUSTUP_TOOLCHAIN" rustc --print sysroot)"
export CARGO="$RUST_SYSROOT/bin/cargo" RUSTC="$RUST_SYSROOT/bin/rustc"
export CARGO_BUILD_JOBS="$JOBS"
export IOS_MIN="${IOS_MIN:-15.0}"
export IPHONEOS_DEPLOYMENT_TARGET="$IOS_MIN"
export IOS_SDK_PATH="${IOS_SDK_PATH:-$(xcrun --sdk iphoneos --show-sdk-path)}"
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-13.5}"
export CC_host="$ROOT/ios/scripts/clang-host.sh"
export CXX_host="$ROOT/ios/scripts/clangxx-host.sh"
export CC_target="$ROOT/ios/scripts/clang-ios.sh"
export CXX_target="$ROOT/ios/scripts/clangxx-ios.sh"
export CC="$CC_target"
export CXX="$CXX_target"
export AR_host="$(xcrun -f ar)" AR_target="$(xcrun -f ar)"
export RANLIB_host="$(xcrun -f ranlib)" RANLIB_target="$(xcrun -f ranlib)"
cd "$SOURCE"
python3 configure --dest-os=ios --dest-cpu=arm64 --cross-compiling \
    --without-node-snapshot --without-node-code-cache --openssl-no-asm \
    --v8-enable-temporal-support
make -C out BUILDTYPE=Release -j"$JOBS" node
echo "Built: $SOURCE/out/Release/node"
