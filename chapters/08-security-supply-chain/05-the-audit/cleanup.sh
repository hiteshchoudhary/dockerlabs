#!/usr/bin/env bash
# Reset this chapter: remove its container, image, and the student-written
# Dockerfile. Never touches the committed scaffold (app/, partner.key).
docker rm -f chai-34-api >/dev/null 2>&1
docker rmi chai-34-api:v1 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch34/app/Dockerfile" 2>/dev/null
echo "  ✔ Chapter 34 reset (chai-34-api container, image and Dockerfile removed)."
exit 0
