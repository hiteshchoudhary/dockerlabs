# Shared helpers for chapter verifiers.
# Verifiers assert on Docker STATE (outcome-based) — never on the exact
# commands typed, so any valid approach passes.

pass() { echo "  ✔ $1"; }
info() { echo "  · $1"; }

fail() {
  echo "  ✘ $1"
  echo
  echo "  Not passing yet — fix it and hit Verify again."
  exit 1
}

celebrate() {
  echo
  echo "  ☕ $1"
}

need_docker() {
  if ! docker info >/dev/null 2>&1; then
    fail "The Docker daemon isn't running. Start Docker Desktop and try again."
  fi
  pass "Docker daemon is up"
}
