#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEVICE="${DEVICE:-root@10.0.0.9}"
PASS="${PASS:-alpine}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if ! command -v sshpass >/dev/null 2>&1; then
  echo "error: sshpass is required for non-interactive deploy" >&2
  exit 1
fi

DEB_PATH="${1:-}"
if [[ -z "${DEB_PATH}" ]]; then
  DEB_PATH="$(find "${ROOT_DIR}/ios/dist" -maxdepth 1 -type f -name 'nodejs22-ios_*_iphoneos-arm.deb' | sort | tail -n 1 || true)"
fi

if [[ -z "${DEB_PATH}" || ! -f "${DEB_PATH}" ]]; then
  echo "error: deb file not found. pass a path or run package script first." >&2
  exit 1
fi

REMOTE_DEB="/tmp/$(basename "${DEB_PATH}")"

sshpass -p "${PASS}" scp ${SSH_OPTS} "${DEB_PATH}" "${DEVICE}:${REMOTE_DEB}"
sshpass -p "${PASS}" ssh ${SSH_OPTS} "${DEVICE}" "dpkg -i '${REMOTE_DEB}'"

echo "installed: ${DEB_PATH} -> ${DEVICE}"
