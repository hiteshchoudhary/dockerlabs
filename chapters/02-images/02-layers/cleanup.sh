#!/usr/bin/env bash
# Reset this chapter: remove its container, its committed image, and
# generated workspace files. Never touches alpine or anything outside
# the chai-05- prefix.
docker rm -f chai-05-lab chai-05-probe >/dev/null 2>&1
docker rmi chai-05-snapshot:v1 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch05/shared-layers.txt" 2>/dev/null
echo "  ✔ Chapter 5 reset (chai-05-lab, chai-05-snapshot:v1 and workspace/ch05 outputs removed)."
exit 0
