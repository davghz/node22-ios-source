#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PATCH_FILE="${ROOT_DIR}/ios/patches/current-worktree.patch"

if [[ ! -f "${PATCH_FILE}" ]]; then
  echo "error: missing patch file: ${PATCH_FILE}" >&2
  exit 1
fi

cd "${ROOT_DIR}"
git apply "${PATCH_FILE}"
echo "applied: ${PATCH_FILE}"
