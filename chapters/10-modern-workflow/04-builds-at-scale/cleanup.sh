#!/usr/bin/env bash
# Reset this chapter: remove its baked images and the student-written bake file.
# The committed scaffold (Dockerfile.api, Dockerfile.worker) stays.
docker rmi -f chai-44-api:v1 chai-44-worker:v1 >/dev/null 2>&1
WS="${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}"
rm -f "$WS/ch44/docker-bake.hcl" 2>/dev/null
echo "  ✔ Chapter 44 reset (chai-44 images and docker-bake.hcl removed)."
exit 0
