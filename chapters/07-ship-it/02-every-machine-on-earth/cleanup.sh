#!/usr/bin/env bash
# Reset this chapter: remove only chai-25-* resources (container, builder, image, outputs).
docker rm -f chai-25-registry >/dev/null 2>&1
docker buildx rm chai-25-builder >/dev/null 2>&1
docker rmi 127.0.0.1:8125/chai-25-api:1.0 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch25/arch.txt" 2>/dev/null
echo "  ✔ Chapter 25 reset (chai-25-registry, chai-25-builder, images and outputs removed)."
exit 0
