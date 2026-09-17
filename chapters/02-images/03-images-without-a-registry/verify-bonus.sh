#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect chai-06-api:v1 >/dev/null 2>&1; then
  fail "chai-06-api:v1 doesn't exist — finish the main exercise first (the challenge compares against it)."
fi
if ! docker image inspect chai-06-flat:v1 >/dev/null 2>&1; then
  fail "No image named 'chai-06-flat:v1'. Export a container and import it: docker export chai-06-box | docker import - chai-06-flat:v1"
fi
pass "Image 'chai-06-flat:v1' exists"

flat_layers=$(docker image inspect -f '{{len .RootFS.Layers}}' chai-06-flat:v1)
if [ "$flat_layers" = "1" ]; then
  pass "Its filesystem is a single flattened layer"
else
  fail "chai-06-flat:v1 has $flat_layers layers — that's not a flattened import (docker import always yields one layer). Build it from an export: docker export chai-06-box | docker import - chai-06-flat:v1"
fi

flat_rows=$(docker history -q chai-06-flat:v1 2>/dev/null | grep -c .)
orig_rows=$(docker history -q chai-06-api:v1 2>/dev/null | grep -c .)
if [ "$flat_rows" -le 2 ]; then
  pass "Its history is gone ($flat_rows row(s) — nothing but the import marker)"
else
  fail "chai-06-flat:v1 has $flat_rows history rows — history survived, so this wasn't made via export/import. Use: docker export chai-06-box | docker import - chai-06-flat:v1"
fi

if [ "$orig_rows" -gt "$flat_rows" ]; then
  pass "The original keeps its full story for contrast ($orig_rows rows vs $flat_rows)"
else
  fail "chai-06-api:v1 shows only $orig_rows history rows — it should still be the full-history original. Re-load it: docker load -i ./ch06/chai-06-api.tar"
fi

celebrate "Challenge complete. You've measured exactly what export throws away."
