#!/usr/bin/env bash
# Reset this chapter: remove its container, image, and generated workspace
# outputs. The committed scaffold (main.go, go.mod, Dockerfile) stays.
docker rm -f chai-43-api chai-43-probe >/dev/null 2>&1
docker rmi chai-43-api:v1 >/dev/null 2>&1
WS="${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}"
rm -f "$WS/ch43/noshell.txt" "$WS/ch43/findings.txt" "$WS/ch43/probe.txt" 2>/dev/null
echo "  ✔ Chapter 43 reset (chai-43-api container+image and ch43 outputs removed)."
exit 0
