#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

keyfile="${LAB_WORKSPACE:?}/ch34/partner.key"
[ -f "$keyfile" ] || fail "Scaffold file workspace/ch34/partner.key is missing — restore it."
key=$(head -n1 "$keyfile" | tr -d '[:space:]')

host_sha256() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  else sha256sum "$1" | cut -d' ' -f1; fi
}

if ! docker container inspect chai-34-api >/dev/null 2>&1; then
  fail "No container 'chai-34-api'. Finish the main exercise first, then re-run it with the key mount and _FILE pointer."
fi
state=$(docker container inspect -f '{{.State.Status}}' chai-34-api)
[ "$state" = "running" ] || fail "chai-34-api is '$state', not running. Check docker logs chai-34-api."
pass "Audited container is (still) running"

# --- the mount ---
mounts=$(docker container inspect -f '{{range .Mounts}}{{.Destination}}|rw={{.RW}} {{end}}' chai-34-api)
mountinfo=""
for m in $mounts; do
  case "$m" in /run/secrets/partner.key|*"/run/secrets|"*) mountinfo="$m" ;; esac
done
if [ -z "$mountinfo" ]; then
  for m in $mounts; do case "$m" in /run/secrets*) mountinfo="$m" ;; esac; done
fi
if [ -z "$mountinfo" ]; then
  fail "No mount under /run/secrets (mounts: '${mounts:-none}'). Re-run with -v \"\$PWD/ch34/partner.key:/run/secrets/partner.key:ro\""
fi
case "$mountinfo" in
  *"rw=false"*) pass "Key mounted at ${mountinfo%%|*} — read-only" ;;
  *) fail "The key mount (${mountinfo%%|*}) is WRITABLE. Add :ro and re-run the container." ;;
esac

# --- the pointer ---
cenv=$(docker container inspect -f '{{range .Config.Env}}{{.}}
{{end}}' chai-34-api)
pointer=$(echo "$cenv" | grep -E '^PARTNER_KEY_FILE=' | head -n1)
if [ "$pointer" != "PARTNER_KEY_FILE=/run/secrets/partner.key" ]; then
  fail "Env pointer is '${pointer:-missing}' — expected PARTNER_KEY_FILE=/run/secrets/partner.key. Add -e PARTNER_KEY_FILE=/run/secrets/partner.key and re-run."
fi
pass "Env carries only the _FILE pointer (a path, not a value)"

# --- the env scan ---
if echo "$cenv" | grep -F "$key" >/dev/null; then
  fail "ENV SCAN FAILED — an environment variable carries the partner key VALUE. Remove that -e; the file mount plus the _FILE pointer is the whole delivery."
fi
suspicious=$(echo "$cenv" | grep -iE '^[A-Za-z_]*(PASSWORD|SECRET|TOKEN|KEY|PRIVATE|CREDENTIAL)[A-Za-z_]*=' | grep -viE '^[A-Za-z_]*_FILE=' || true)
if [ -n "$suspicious" ]; then
  fail "ENV SCAN FAILED — secret-smelling variable(s) in env: $(echo "$suspicious" | cut -d= -f1 | tr '\n' ' '). Only _FILE pointers are acceptable; deliver values as files."
fi
pass "ENV SCAN CLEAN — no secret values, no secret-named variables (only _FILE pointers)"

# --- the app actually loaded it ---
expected=$(host_sha256 "$keyfile")
body=$(curl -fsS --max-time 5 http://127.0.0.1:8034/ 2>/dev/null)
[ -n "$body" ] || fail "No HTTP answer on 8034 — is the container up? docker logs chai-34-api."
echo "$body" | grep -q '"partnerKeyLoaded":true' \
  || fail "The API reports partnerKeyLoaded:false — the file isn't at /run/secrets/partner.key inside, or the pointer path is wrong."
echo "$body" | grep -qF "\"partnerKeyFingerprint\":\"$expected\"" \
  || fail "The key fingerprint doesn't match workspace/ch34/partner.key — a different file is mounted."
pass "API loaded the partner key from the file — fingerprint verified, value never exposed"

celebrate "Challenge complete. Full sign-off: hardened, healthy, and not a secret in sight."
