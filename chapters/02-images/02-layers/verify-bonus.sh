#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect chai-05-snapshot:v1 >/dev/null 2>&1; then
  fail "chai-05-snapshot:v1 doesn't exist — finish the main exercise first."
fi
if ! docker image inspect alpine >/dev/null 2>&1; then
  fail "The 'alpine' image isn't present locally. Pull it: docker pull alpine"
fi

snap_layers=$(docker image inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' chai-05-snapshot:v1 | grep -oE 'sha256:[0-9a-f]{64}' | sort -u)
base_layers=$(docker image inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' alpine | grep -oE 'sha256:[0-9a-f]{64}' | sort -u)
shared=$(comm -12 <(echo "$snap_layers") <(echo "$base_layers"))
if [ -z "$shared" ]; then
  fail "The two images share no layers — chai-05-snapshot:v1 doesn't sit on this alpine. Re-do the exercise from an alpine container."
fi
count=$(echo "$shared" | grep -c .)
pass "The images really share $count layer(s) on disk"

sharedfile="${LAB_WORKSPACE:?}/ch05/shared-layers.txt"
if [ ! -f "$sharedfile" ]; then
  fail "No file at workspace/ch05/shared-layers.txt. Write the shared layer digest(s) there — compare the two images' .RootFS.Layers lists."
fi

written=$(grep -oE 'sha256:[0-9a-f]{64}' "$sharedfile" | sort -u)
if [ -z "$written" ]; then
  fail "workspace/ch05/shared-layers.txt has no sha256:<64-hex> digests in it. List layers with: docker image inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' <image>"
fi

if [ "$written" = "$shared" ]; then
  pass "shared-layers.txt lists exactly the digests both images have in common"
else
  fail "shared-layers.txt doesn't match the real intersection. It must contain every digest present in BOTH images' .RootFS.Layers — and nothing else."
fi

celebrate "Challenge complete. Layer sharing isn't a diagram — you just measured it."
