#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

for v in chai-15-data chai-15-restore; do
  if ! docker volume inspect "$v" >/dev/null 2>&1; then
    fail "Volume '$v' doesn't exist — finish the main exercise first."
  fi
done

orig=$(docker run --rm --name chai-15-probe -v chai-15-data:/data:ro alpine cat /data/notes/brew.txt 2>/dev/null)
if [ "$orig" = "first brew at 6am" ]; then
  pass "Original chai-15-data/notes/brew.txt untouched: '$orig'"
else
  fail "chai-15-data's notes/brew.txt reads '${orig:-nothing}' — you modified the ORIGINAL. That's the anti-lesson: fix the source (re-seed it with 'first brew at 6am') and modify only chai-15-restore."
fi

rest=$(docker run --rm --name chai-15-probe -v chai-15-restore:/data:ro alpine cat /data/notes/brew.txt 2>/dev/null)
if [ -z "$rest" ]; then
  fail "chai-15-restore has no /data/notes/brew.txt. Restore first, then overwrite it: docker run --rm -v chai-15-restore:/data alpine sh -c 'echo \"second brew, extra ginger\" > /data/notes/brew.txt'"
fi

if [ "$rest" != "$orig" ]; then
  pass "Restored copy diverged ('$rest') while the original didn't — the volumes share nothing"
else
  fail "notes/brew.txt is identical in both volumes — overwrite it in chai-15-restore (and only there): docker run --rm -v chai-15-restore:/data alpine sh -c 'echo \"second brew, extra ginger\" > /data/notes/brew.txt'"
fi

celebrate "Challenge complete. Independence proven — a restore drill you can trust."
