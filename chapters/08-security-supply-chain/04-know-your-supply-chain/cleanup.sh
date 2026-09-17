#!/usr/bin/env bash
# Reset this chapter: remove its registry container, buildx builder, image,
# and the student-written Dockerfile. The committed buildkitd.toml stays.
docker rm -f chai-33-registry >/dev/null 2>&1
docker buildx rm -f chai-33-builder >/dev/null 2>&1
docker rmi chai-33-api:v1 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch33/Dockerfile" 2>/dev/null
echo "  ✔ Chapter 33 reset (chai-33-registry, chai-33-builder, chai-33-api:v1 and Dockerfile removed)."
exit 0
