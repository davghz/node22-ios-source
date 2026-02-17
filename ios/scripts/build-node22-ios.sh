#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
JOBS="${JOBS:-$(sysctl -n hw.logicalcpu 2>/dev/null || echo 8)}"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || true)}"
IOS_MIN="${IOS_MIN:-13.0}"

if [[ -z "${PYTHON_BIN}" ]]; then
  echo "error: python3 not found in PATH and PYTHON_BIN is not set" >&2
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "error: xcrun is required (install Xcode command line tools)" >&2
  exit 1
fi

export IOS_MIN
if [[ -z "${IOS_SDK_PATH:-}" && -d "/Users/davgz/theos/sdks/iPhoneOS13.7.sdk" ]]; then
  export IOS_SDK_PATH="/Users/davgz/theos/sdks/iPhoneOS13.7.sdk"
fi
export CC_host="${ROOT_DIR}/ios/scripts/clang-host.sh"
export CXX_host="${ROOT_DIR}/ios/scripts/clangxx-host.sh"
export CC_target="${ROOT_DIR}/ios/scripts/clang-ios.sh"
export CXX_target="${ROOT_DIR}/ios/scripts/clangxx-ios.sh"
export CC="${CC_target}"
export CXX="${CXX_target}"
export AR_host="$(xcrun -f ar)"
export RANLIB_host="$(xcrun -f ranlib)"
export AR_target="$(xcrun -f ar)"
export RANLIB_target="$(xcrun -f ranlib)"

cd "${ROOT_DIR}"

if [[ "${CLEAN:-1}" == "1" ]]; then
  rm -rf out
fi

PYTHON="${PYTHON_BIN}" ./configure \
  --dest-cpu=arm64 \
  --dest-os=ios \
  --cross-compiling \
  --without-node-snapshot \
  --openssl-no-asm

make -C out BUILDTYPE=Release V="${V:-0}" -j"${JOBS}"

echo "build complete: ${ROOT_DIR}/out/Release/node"
