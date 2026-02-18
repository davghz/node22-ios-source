#!/usr/bin/env bash
set -euo pipefail

DEVICE="${DEVICE:-root@10.0.0.9}"
PASS="${PASS:-alpine}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
REPS="${REPS:-5}"
NODE="/usr/local/bin/node22"

if ! command -v sshpass >/dev/null 2>&1; then
  echo "error: sshpass is required for non-interactive smoke tests" >&2
  exit 1
fi

run_remote() {
  sshpass -p "${PASS}" ssh ${SSH_OPTS} "${DEVICE}" "$1" 2>/dev/null
}

passed=0
failed=0
results=()

run_test() {
  local name="$1"
  local cmd="$2"
  local expect_stdout="${3:-}"
  local ok=0
  local fail=0
  for ((r=1; r<=REPS; r++)); do
    output=""
    rc=0
    output=$(run_remote "${cmd}") || rc=$?
    if [ "$rc" -ne 0 ]; then
      fail=$((fail + 1))
    elif [ -n "$expect_stdout" ] && [ "$output" != "$expect_stdout" ]; then
      fail=$((fail + 1))
    else
      ok=$((ok + 1))
    fi
  done
  if [ "$fail" -eq 0 ]; then
    results+=("PASS  ${name}  (${ok}/${REPS})")
    passed=$((passed + 1))
  else
    results+=("FAIL  ${name}  (${ok}/${REPS} ok, ${fail}/${REPS} failed)")
    failed=$((failed + 1))
  fi
}

echo "=== Node22 iOS Smoke Tests (${REPS} reps each) ==="
echo ""

# Basic checks (1 rep)
REPS_SAVE="$REPS"
REPS=1

run_test "node_version" "${NODE} -v"
run_test "npm_version" "/usr/local/bin/npm22 --version"
run_test "v8_version" "${NODE} -e 'console.log(process.versions.v8)'"
run_test "wasm_typeof" \
  "${NODE} -e 'console.log(typeof WebAssembly === \"object\" ? \"wasm_ok\" : \"wasm_missing\")'" \
  "wasm_ok"

REPS="$REPS_SAVE"

# Entitlements validation (1 rep)
REPS_SAVE="$REPS"
REPS=1
run_test "entitlements" \
  "ldid -e ${NODE} | grep -q dynamic-codesigning && echo ent_ok" \
  "ent_ok"
REPS="$REPS_SAVE"

# Stress tests (REPS reps)
run_test "js_loop_stress" \
  "${NODE} -e 'for(let i=0;i<1e6;i++){}; console.log(\"ok\")'" \
  "ok"

run_test "wasm_compile" \
  "${NODE} -e 'new WebAssembly.Module(new Uint8Array([0,97,115,109,1,0,0,0])); console.log(\"ok\")'" \
  "ok"

# WASM module that exports fn() returning 42
WASM_42='const bytes=new Uint8Array([0,97,115,109,1,0,0,0,1,5,1,96,0,1,127,3,2,1,0,7,6,1,2,102,110,0,0,10,6,1,4,0,65,42,11]);'
WASM_42+='const m=new WebAssembly.Module(bytes);'
WASM_42+='const i=new WebAssembly.Instance(m);'
WASM_42+='console.log(i.exports.fn())'

run_test "wasm_execute" \
  "${NODE} -e '${WASM_42}'" \
  "42"

# Summary
echo ""
printf "%-6s  %s\n" "------" "----------------------------------------"
for r in "${results[@]}"; do
  printf "%s\n" "$r"
done
printf "%-6s  %s\n" "------" "----------------------------------------"
echo ""
total=$((passed + failed))
echo "Result: ${passed}/${total} passed, ${failed}/${total} failed"

if [ "$failed" -gt 0 ]; then
  echo "SMOKE TEST FAILED"
  exit 1
fi
echo "SMOKE TEST PASSED"
