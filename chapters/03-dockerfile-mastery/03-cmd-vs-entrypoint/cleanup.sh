#!/usr/bin/env bash
# Reset this chapter: remove its containers, image, and the student-written
# Dockerfile (committed scaffolding — greet.sh — stays).
docker rm -f chai-09-peek chai-09-probe >/dev/null 2>&1
docker rmi -f chai-09-tool:v1 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch09/Dockerfile" 2>/dev/null
echo "  ✔ Chapter 9 reset (chai-09 containers, image, and Dockerfile removed)."
exit 0
