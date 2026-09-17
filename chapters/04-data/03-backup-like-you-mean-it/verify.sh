#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker volume inspect chai-15-data >/dev/null 2>&1; then
  fail "No volume named 'chai-15-data' found. Create and seed it: docker volume create chai-15-data, then a --rm alpine helper writes /data/menu.txt and /data/notes/brew.txt."
fi
pass "Volume 'chai-15-data' exists"

if ! docker volume inspect chai-15-restore >/dev/null 2>&1; then
  fail "No volume named 'chai-15-restore' found. Create it (docker volume create chai-15-restore) and extract the backup into it."
fi
pass "Volume 'chai-15-restore' exists"

tarball="${LAB_WORKSPACE:?}/ch15/backup.tar.gz"
if [ ! -f "$tarball" ]; then
  fail "No file at workspace/ch15/backup.tar.gz. Run the tar pattern: docker run --rm -v chai-15-data:/data:ro -v \"\$(pwd)/ch15\":/backup alpine tar czf /backup/backup.tar.gz -C /data ."
fi

listing=$(tar tzf "$tarball" 2>/dev/null)
if [ -z "$listing" ]; then
  fail "workspace/ch15/backup.tar.gz exists but isn't a readable gzipped tar. Recreate it with: tar czf /backup/backup.tar.gz -C /data .  (c=create, z=gzip, f=file)"
fi
pass "backup.tar.gz is a valid gzipped tar"

if echo "$listing" | grep -Eq '^(\./)?menu\.txt$' && echo "$listing" | grep -Eq '^(\./)?notes/brew\.txt$'; then
  pass "…containing menu.txt and notes/brew.txt as relative paths"
elif echo "$listing" | grep -Eq '(^|/)menu\.txt$'; then
  fail "The archive has menu.txt buried under a path prefix (tar tzf shows: $(echo "$listing" | tr '\n' ' ')) — restoring would land files in the wrong place (/data/data/...). Archive relative paths: tar czf /backup/backup.tar.gz -C /data ."
else
  fail "The archive doesn't contain menu.txt and notes/brew.txt (tar tzf shows: $(echo "$listing" | tr '\n' ' ')). Seed chai-15-data first, then back it up with -C /data ."
fi

restored=$(docker run --rm --name chai-15-probe -v chai-15-restore:/data:ro alpine cat /data/menu.txt 2>/dev/null)
if [ "$restored" != "masala chai, strong, no sugar" ]; then
  fail "Inside chai-15-restore, /data/menu.txt reads '${restored:-nothing}' — expected 'masala chai, strong, no sugar'. Extract the backup into it: docker run --rm -v chai-15-restore:/data -v \"\$(pwd)/ch15\":/backup alpine tar xzf /backup/backup.tar.gz -C /data"
fi
pass "Restored volume serves menu.txt back, byte-for-byte"

original=$(docker run --rm --name chai-15-probe -v chai-15-data:/data:ro alpine cat /data/menu.txt 2>/dev/null)
if [ "$original" = "masala chai, strong, no sugar" ]; then
  pass "…and the original volume is intact"
else
  fail "chai-15-data's /data/menu.txt reads '${original:-nothing}' — the source should contain exactly 'masala chai, strong, no sugar'. Re-seed it and back up again."
fi

celebrate "Exercise 15.1 complete. Seed, archive, restore, verify — a backup you have actually restored."
