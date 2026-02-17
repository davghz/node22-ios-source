#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_NAME="${PKG_NAME:-nodejs22-ios}"
VERSION="${VERSION:-22.12.0-18}"
ARCH="${ARCH:-iphoneos-arm}"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/ios/dist}"
PKG_ROOT="${PKG_ROOT:-${ROOT_DIR}/ios/pkg/${PKG_NAME}}"
NODE_BIN="${NODE_BIN:-${ROOT_DIR}/out/Release/node}"
NPM_SRC="${NPM_SRC:-${ROOT_DIR}/deps/npm}"
DEB_PATH="${OUT_DIR}/${PKG_NAME}_${VERSION}_${ARCH}.deb"

for cmd in rsync dpkg-deb; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: required command not found: ${cmd}" >&2
    exit 1
  fi
done

if [[ ! -x "${NODE_BIN}" ]]; then
  echo "error: node binary not found: ${NODE_BIN}" >&2
  echo "hint: run ios/scripts/build-node22-ios.sh first" >&2
  exit 1
fi

if [[ ! -d "${NPM_SRC}" ]]; then
  echo "error: npm source directory not found: ${NPM_SRC}" >&2
  exit 1
fi

rm -rf "${PKG_ROOT}"
mkdir -p "${PKG_ROOT}/DEBIAN"
mkdir -p "${PKG_ROOT}/usr/local/bin"
mkdir -p "${PKG_ROOT}/usr/local/lib/node22/node_modules"
mkdir -p "${OUT_DIR}"

install -m 0755 "${NODE_BIN}" "${PKG_ROOT}/usr/local/bin/node22"

rsync -a --delete \
  --exclude='.git' \
  --exclude='.github' \
  "${NPM_SRC}/" "${PKG_ROOT}/usr/local/lib/node22/node_modules/npm/"

cat > "${PKG_ROOT}/usr/local/bin/npm22" <<'EOF'
#!/bin/sh
exec /usr/local/bin/node22 /usr/local/lib/node22/node_modules/npm/bin/npm-cli.js "$@"
EOF

cat > "${PKG_ROOT}/usr/local/bin/npx22" <<'EOF'
#!/bin/sh
exec /usr/local/bin/node22 /usr/local/lib/node22/node_modules/npm/bin/npx-cli.js "$@"
EOF

chmod 0755 "${PKG_ROOT}/usr/local/bin/npm22" "${PKG_ROOT}/usr/local/bin/npx22"

sed \
  -e "s|@VERSION@|${VERSION}|g" \
  "${ROOT_DIR}/ios/packaging/control.in" \
  > "${PKG_ROOT}/DEBIAN/control"

install -m 0755 \
  "${ROOT_DIR}/ios/packaging/postinst" \
  "${PKG_ROOT}/DEBIAN/postinst"

if command -v ldid >/dev/null 2>&1; then
  ldid -S"${ROOT_DIR}/ios/packaging/node22-jit.entitlements" \
    "${PKG_ROOT}/usr/local/bin/node22" || true
fi

rm -f "${DEB_PATH}"
dpkg-deb -b "${PKG_ROOT}" "${DEB_PATH}" >/dev/null
echo "${DEB_PATH}"
