#!/usr/bin/env bash
set -euo pipefail

DEVICE="${DEVICE:-root@10.0.0.9}"
PASS="${PASS:-alpine}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if ! command -v sshpass >/dev/null 2>&1; then
  echo "error: sshpass is required for non-interactive smoke tests" >&2
  exit 1
fi

run_remote() {
  local cmd="$1"
  sshpass -p "${PASS}" ssh ${SSH_OPTS} "${DEVICE}" "${cmd}"
}

run_remote "/usr/local/bin/node22 -v"
run_remote "/usr/local/bin/node22 -e 'console.log(\"node_ok\")'"
run_remote "/usr/local/bin/node22 -e 'console.log(typeof WebAssembly === \"object\" ? \"wasm_ok\" : \"wasm_missing\")'"
run_remote "/usr/local/bin/npm22 --version"
run_remote "/usr/local/bin/node22 -e 'console.log(process.versions.v8)'"

echo "smoke test complete on ${DEVICE}"
