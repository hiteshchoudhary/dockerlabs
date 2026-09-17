#!/usr/bin/env bash
# Reset this chapter: remove its container, volume, and generated outputs.
docker rm -f chai-36-qdrant >/dev/null 2>&1
docker volume rm chai-36-data >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch36/survived.txt" 2>/dev/null
echo "  ✔ Chapter 36 reset (chai-36-qdrant, volume chai-36-data, and workspace/ch36 outputs removed)."
exit 0
