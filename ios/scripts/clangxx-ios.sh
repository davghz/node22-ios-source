#!/usr/bin/env bash
# Cross-compiler wrapper for iOS arm64 target (C++)
set -euo pipefail

find_compiler() {
  local tool="$1"
  local cc
  cc="$(xcrun -f "${tool}")"
  local toolchain_usr
  toolchain_usr="$(cd "$(dirname "${cc}")/.." && pwd)"
  if [[ -d "${toolchain_usr}/include/c++/v1" ]]; then
    echo "${cc}"
    return 0
  fi

  local candidate
  for candidate in \
    "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/${tool}" \
    "/Applications/Xcode copy.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/${tool}"; do
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done

  echo "${cc}"
}

REAL_CXX="$(find_compiler clang++)"
IOS_SDK="${IOS_SDK_PATH:-}"
if [[ -z "${IOS_SDK}" ]]; then
  IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${IOS_SDK}" ]]; then
  IOS_SDK="/Users/davgz/theos/sdks/iPhoneOS13.7.sdk"
fi
if [[ ! -d "${IOS_SDK}" ]]; then
  echo "error: iPhoneOS SDK not found (set IOS_SDK_PATH)" >&2
  exit 1
fi
IOS_MIN="${IOS_MIN:-13.0}"
IOS_TARGET="arm64-apple-ios${IOS_MIN}"

args=()
for a in "$@"; do
  case "$a" in
    -Wl,--start-group|-Wl,--end-group|--start-group|--end-group)
      # Strip GNU ld flags unsupported by Apple ld
      ;;
    *)
      args+=("$a")
      ;;
  esac
done

exec "$REAL_CXX" -target "$IOS_TARGET" -isysroot "$IOS_SDK" "-miphoneos-version-min=${IOS_MIN}" "${args[@]}"
