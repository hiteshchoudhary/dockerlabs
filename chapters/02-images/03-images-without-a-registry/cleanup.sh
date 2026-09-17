#!/usr/bin/env bash
# Reset this chapter: remove its container, its images, and generated
# workspace files. Never touches nginx:alpine or anything outside the
# chai-06- prefix.
docker rm -f chai-06-box >/dev/null 2>&1
docker rmi chai-06-api:v1 chai-06-flat:v1 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch06/chai-06-api.tar" 2>/dev/null
echo "  ✔ Chapter 6 reset (chai-06-box, chai-06-api:v1, chai-06-flat:v1 and workspace/ch06 outputs removed)."
exit 0
