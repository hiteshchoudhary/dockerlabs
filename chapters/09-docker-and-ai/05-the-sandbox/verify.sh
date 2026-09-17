#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-39-sandbox >/dev/null 2>&1; then
  fail "No container named 'chai-39-sandbox'. Run untrusted.py in the hardened container from the chapter (and do NOT use --rm — it must persist for inspection)."
fi
pass "Container 'chai-39-sandbox' exists"

img=$(docker container inspect -f '{{.Config.Image}}' chai-39-sandbox)
case "$img" in
  python:3.12-alpine) pass "Built from python:3.12-alpine" ;;
  *) fail "Container uses image '$img' — expected python:3.12-alpine." ;;
esac

# --- inspect EVERY jail bar independently ---

net=$(docker container inspect -f '{{.HostConfig.NetworkMode}}' chai-39-sandbox)
[ "$net" = "none" ] && pass "Bar 1/6: network is 'none' (no network stack)" \
  || fail "NetworkMode is '$net', not 'none'. Add --network none."

ro=$(docker container inspect -f '{{.HostConfig.ReadonlyRootfs}}' chai-39-sandbox)
[ "$ro" = "true" ] && pass "Bar 2/6: root filesystem is read-only" \
  || fail "ReadonlyRootfs is '$ro'. Add --read-only (and --tmpfs /tmp so legit writes still work)."

caps=$(docker container inspect -f '{{.HostConfig.CapDrop}}' chai-39-sandbox)
case "$caps" in
  *ALL*) pass "Bar 3/6: all Linux capabilities dropped" ;;
  *) fail "CapDrop is '$caps' — expected it to contain ALL. Add --cap-drop ALL." ;;
esac

pids=$(docker container inspect -f '{{.HostConfig.PidsLimit}}' chai-39-sandbox)
[ "$pids" = "64" ] && pass "Bar 4/6: PID limit is 64 (fork bombs hit a wall)" \
  || fail "PidsLimit is '$pids', expected 64. Add --pids-limit 64."

mem=$(docker container inspect -f '{{.HostConfig.Memory}}' chai-39-sandbox)
[ "$mem" = "134217728" ] && pass "Bar 5/6: memory capped at 128 MB" \
  || fail "Memory is '$mem' bytes, expected 134217728 (128m). Add --memory 128m."

user=$(docker container inspect -f '{{.Config.User}}' chai-39-sandbox)
if [ -z "$user" ] || [ "$user" = "root" ] || [ "$user" = "0" ] || [ "${user%%:*}" = "0" ]; then
  fail "User is '${user:-<empty = root>}' — the sandbox must run as non-root. Add --user 65534:65534."
fi
pass "Bar 6/6: runs as non-root user ($user)"

# --- the container must have EXITED (it's a one-shot jail) ---
state=$(docker container inspect -f '{{.State.Status}}' chai-39-sandbox)
[ "$state" = "exited" ] && pass "The one-shot jail ran and exited" \
  || info "Container state is '$state' (expected exited — the script runs once and stops)"

# --- captured output: legit work succeeded ---
out="${LAB_WORKSPACE:?}/ch39/output.txt"
if [ ! -f "$out" ]; then
  fail "No file at workspace/ch39/output.txt. Capture the run: docker run ... > ./ch39/output.txt 2>&1 (or docker logs chai-39-sandbox > ./ch39/output.txt)."
fi
if grep -q "RESULT: 42" "$out" && grep -q "wrote /tmp/result.txt" "$out"; then
  pass "Legitimate work survived the jail (RESULT: 42, wrote to /tmp)"
else
  fail "output.txt doesn't show the legit work succeeding (RESULT: 42 + a /tmp write). Did you include --tmpfs /tmp? Without it the script can't write its result."
fi

# --- the drama: every attack provably BLOCKED ---
miss=""
grep -q "\[network\] BLOCKED" "$out"    || miss="$miss network"
grep -q "\[filesystem\] BLOCKED" "$out" || miss="$miss filesystem"
grep -q "\[fork-bomb\] BLOCKED" "$out"  || miss="$miss fork-bomb"
if [ -z "$miss" ]; then
  pass "All three attacks BLOCKED (network, filesystem, fork-bomb)"
else
  if grep -q "ESCAPED" "$out"; then
    fail "An attack ESCAPED —$miss not blocked. A missing flag left a door open; re-check --network none / --read-only / --pids-limit against the chapter."
  fi
  fail "output.txt doesn't confirm all attacks blocked (missing:$miss). Re-run in the full jail and re-capture."
fi

celebrate "Exercise 39.1 complete. Untrusted code ran, produced its answer, and escaped nothing."
