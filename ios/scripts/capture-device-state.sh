#!/usr/bin/env bash
# capture-device-state.sh — Capture device state and crash matrix for diagnosis.
set -euo pipefail

DEVICE="${DEVICE:-root@10.0.0.9}"
PASS="${PASS:-alpine}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
REPS="${REPS:-5}"
NODE="/usr/local/bin/node22"

run_remote() {
  sshpass -p "${PASS}" ssh ${SSH_OPTS} "${DEVICE}" "$1" 2>/dev/null
}

echo "=== Device State Capture ==="
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

echo "--- Binary Info ---"
run_remote "file ${NODE}" || echo "(file command failed)"
echo ""

echo "--- Entitlements ---"
run_remote "ldid -e ${NODE}" || echo "(ldid not found or failed)"
echo ""

echo "--- Node Version ---"
run_remote "${NODE} -v" || echo "(node22 not found)"
echo ""

echo "--- V8 Version ---"
run_remote "${NODE} -e 'console.log(process.versions.v8)'" || echo "(failed)"
echo ""

echo "--- Crash Matrix (${REPS} reps each) ---"
tests=(
  "js_loop:${NODE} -e 'for(let i=0;i<1e6;i++){}; console.log(\"ok\")'"
  "wasm_compile:${NODE} -e 'new WebAssembly.Module(new Uint8Array([0,97,115,109,1,0,0,0])); console.log(\"ok\")'"
  "wasm_execute:${NODE} -e 'const m=new WebAssembly.Module(new Uint8Array([0,97,115,109,1,0,0,0,1,5,1,96,0,1,127,3,2,1,0,7,6,1,2,102,110,0,0,10,6,1,4,0,65,42,11])); const i=new WebAssembly.Instance(m); console.log(i.exports.fn())'"
  "npm_version:/usr/local/bin/npm22 --version"
)

declare -A pass_counts
declare -A fail_counts
declare -A signals_seen

for t in "${tests[@]}"; do
  name="${t%%:*}"
  cmd="${t#*:}"
  pass_counts[$name]=0
  fail_counts[$name]=0
  signals_seen[$name]=""
  for ((r=1; r<=REPS; r++)); do
    rc=0
    run_remote "${cmd}" >/dev/null 2>&1 || rc=$?
    if [ "$rc" -eq 0 ]; then
      pass_counts[$name]=$(( ${pass_counts[$name]} + 1 ))
    else
      fail_counts[$name]=$(( ${fail_counts[$name]} + 1 ))
      signals_seen[$name]="${signals_seen[$name]} rc=${rc}"
    fi
  done
done

printf "\n%-15s  %-6s  %-6s  %s\n" "TEST" "PASS" "FAIL" "SIGNALS"
printf "%-15s  %-6s  %-6s  %s\n" "---------------" "------" "------" "-------"
for t in "${tests[@]}"; do
  name="${t%%:*}"
  printf "%-15s  %-6s  %-6s  %s\n" \
    "$name" "${pass_counts[$name]}" "${fail_counts[$name]}" "${signals_seen[$name]:-none}"
done

echo ""
echo "--- Kernel Fault Log (last 20 lines) ---"
run_remote "dmesg 2>/dev/null | grep -i fault | tail -20" || echo "(dmesg unavailable)"
echo ""
echo "=== Capture Complete ==="
