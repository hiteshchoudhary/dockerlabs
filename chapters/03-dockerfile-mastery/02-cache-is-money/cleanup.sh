#!/usr/bin/env bash
# Reset this chapter: remove its container, image, and student-generated files.
# Committed scaffolding (server.js, package.json, package-lock.json) stays.
docker rm -f chai-08-api chai-08-probe >/dev/null 2>&1
docker rmi -f chai-08-api:v1 >/dev/null 2>&1
WS="${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}"
rm -f "$WS/ch08/app/Dockerfile" "$WS/ch08/app/.dockerignore" "$WS/ch08/app/secret.env" 2>/dev/null
rm -rf "$WS/ch08/app/node_modules" 2>/dev/null
echo "  ✔ Chapter 8 reset (chai-08 container, image, Dockerfile, .dockerignore, secret.env removed)."
exit 0
