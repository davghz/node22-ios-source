#!/usr/bin/env bash
# Cross-compiler wrapper for iOS arm64 target
set -euo pipefail
REAL_CC="$(xcrun -f clang)"
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

exec "$REAL_CC" -target "$IOS_TARGET" -isysroot "$IOS_SDK" "-miphoneos-version-min=${IOS_MIN}" "${args[@]}"
