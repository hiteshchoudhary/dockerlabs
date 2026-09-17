#!/usr/bin/env bash
# Reset this chapter: remove only chai-29-* resources and generated outputs.
docker rm -f chai-29-app chai-29-registry >/dev/null 2>&1
docker rmi 127.0.0.1:8129/chai-29-app:1.0 127.0.0.1:8129/chai-29-app:2.0 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch29/rollback.txt" 2>/dev/null
echo "  ✔ Chapter 29 reset (chai-29 app, registry, images and rollback note removed)."
exit 0
