#!/usr/bin/env bash
set -euo pipefail

REAL_CXX="$(xcrun -f clang++)"
MACOS_SDK="$(xcrun --sdk macosx --show-sdk-path)"

args=()
is_compile=0
output_file=""
prev_was_o=0
for a in "$@"; do
  if [ "$prev_was_o" -eq 1 ]; then
    output_file="$a"
    prev_was_o=0
  fi
  case "$a" in
    -Wl,--start-group|-Wl,--end-group|--start-group|--end-group)
      ;;
    -c|-S|-E)
      is_compile=1
      args+=("$a")
      ;;
    -o)
      prev_was_o=1
      args+=("$a")
      ;;
    *)
      args+=("$a")
      ;;
  esac
done

"$REAL_CXX" -isysroot "$MACOS_SDK" -mmacosx-version-min=11.0 "${args[@]}"
if [ "$is_compile" -eq 0 ] && [ -n "$output_file" ] && [ -f "$output_file" ]; then
  codesign -s - "$output_file" 2>/dev/null || true
fi
