#!/usr/bin/env bash
# Repackage the tested v22.12.0-26 iOS release for a rootless bootstrap.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INPUT="${1:?Usage: package-rootless-deb.sh /path/to/nodejs22-ios_22.12.0-26_iphoneos-arm.deb}"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/node22-rootless.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
[ "$(dpkg-deb -f "$INPUT" Package)" = nodejs22-ios ]
[ "$(dpkg-deb -f "$INPUT" Version)" = 22.12.0-26 ]
dpkg-deb -x "$INPUT" "$STAGE/input"
PKG="$STAGE/pkg"
mkdir -p "$PKG/DEBIAN" "$PKG/var/jb/usr/bin" "$ROOT/ios/dist"
cp "$STAGE/input/usr/local/bin/node22" "$PKG/var/jb/usr/bin/node22"
cat > "$PKG/DEBIAN/control" <<'EOF'
Package: nodejs22-ios
Name: Node.js 22 (Rootless)
Version: 22.12.0-27+rootless
Architecture: iphoneos-arm64
Maintainer: davgz
Depends: firmware (>= 15.0), dash
Section: Development
Description: Native Node.js 22.12.0 for rootless iOS
 Repackages the tested iOS release under /var/jb. npm is packaged separately.
EOF
cat > "$PKG/var/jb/usr/bin/node" <<'EOF'
#!/var/jb/bin/sh
# Retain the port's stable V8 settings; WebAssembly remains available.
exec /var/jb/usr/bin/node22 --max-opt=0 --no-sparkplug \
    --max-old-space-size=512 --disable-wasm-trap-handler "$@"
EOF
python3 - "$ROOT/ios/packaging/node22-jit.entitlements" "$STAGE/entitlements.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'rb') as f:
    entitlements = plistlib.load(f)
entitlements['com.apple.private.security.no-container'] = True
with open(sys.argv[2], 'wb') as f:
    plistlib.dump(entitlements, f)
PY
ldid -S"$STAGE/entitlements.plist" "$PKG/var/jb/usr/bin/node22"
chmod 755 "$PKG/var/jb/usr/bin/"*
OUTPUT="$ROOT/ios/dist/nodejs22-ios_22.12.0-27+rootless_iphoneos-arm64.deb"
dpkg-deb --root-owner-group -Zgzip -b "$PKG" "$OUTPUT"
echo "Built: $OUTPUT"
