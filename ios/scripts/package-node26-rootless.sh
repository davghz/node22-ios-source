#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BINARY="${1:?Usage: package-node26-rootless.sh /path/to/node-v26.13.1/out/Release/node}"
SOURCE="${NODE26_SOURCE:-$ROOT/ios/work/node-v26.13.1}"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/node26-rootless.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
chmod 755 "$STAGE"
otool -l "$BINARY" | awk '
    $1 == "cmd" { build = ($2 == "LC_BUILD_VERSION") }
    build && $1 == "platform" && $2 == 2 { ios = 1 }
    END { exit !ios }
' || { echo 'Expected an iOS device executable' >&2; exit 1; }
mkdir -p "$STAGE/DEBIAN" "$STAGE/var/jb/usr/bin" \
    "$STAGE/var/jb/usr/libexec/node26" "$STAGE/var/jb/usr/share/doc/nodejs22-ios"
cp "$BINARY" "$STAGE/var/jb/usr/libexec/node26/node"
cp "$SOURCE/LICENSE" "$STAGE/var/jb/usr/share/doc/nodejs22-ios/copyright"
python3 - "$ROOT/ios/packaging/node22-jit.entitlements" "$STAGE/entitlements.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'rb') as f:
    entitlements = plistlib.load(f)
entitlements['com.apple.private.security.no-container'] = True
with open(sys.argv[2], 'wb') as f:
    plistlib.dump(entitlements, f)
PY
ldid -S"$STAGE/entitlements.plist" "$STAGE/var/jb/usr/libexec/node26/node"
rm "$STAGE/entitlements.plist"
cat > "$STAGE/var/jb/usr/bin/node26" <<'EOF'
#!/var/jb/bin/sh
exec /var/jb/usr/libexec/node26/node --max-opt=0 --no-sparkplug \
    --regexp-interpret-all --liftoff-only --no-wasm-async-compilation \
    --max-old-space-size=512 --disable-wasm-trap-handler "$@"
EOF
ln -s node26 "$STAGE/var/jb/usr/bin/node"
# Preserve existing scripts while reporting the real new runtime version.
ln -s node26 "$STAGE/var/jb/usr/bin/node22"
chmod 755 "$STAGE/var/jb/usr/bin/node26" "$STAGE/var/jb/usr/libexec/node26/node"
cat > "$STAGE/DEBIAN/control" <<'EOF'
Package: nodejs22-ios
Name: Node.js 26 (Rootless)
Version: 26.13.1-1+rootless
Architecture: iphoneos-arm64
Maintainer: davgz
Depends: firmware (>= 15.0), dash, ca-certificates
Section: Development
Description: Native Node.js 26.13.1 for rootless iOS
 Built from the pinned upstream release for arm64 iOS 15 and installed under
 /var/jb. Includes node26, node, and a legacy node22 command alias. npm is separate.
EOF
mkdir -p "$ROOT/ios/dist"
OUTPUT="$ROOT/ios/dist/nodejs22-ios_26.13.1-1+rootless_iphoneos-arm64.deb"
dpkg-deb --root-owner-group -Zgzip -b "$STAGE" "$OUTPUT"
python3 - "$OUTPUT" <<'PY'
import hashlib, pathlib, sys
p = pathlib.Path(sys.argv[1])
p.with_suffix(p.suffix + '.sha256').write_text(hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.name + '\n')
PY
echo "Built: $OUTPUT"
