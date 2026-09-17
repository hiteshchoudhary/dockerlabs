#!/usr/bin/env bash
# Reset this chapter: remove its container and the student-written devcontainer
# definition. The committed scaffold (package.json, server.js) stays.
docker rm -f chai-41-dev >/dev/null 2>&1
WS="${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}"
rm -rf "$WS/ch41/project/.devcontainer" 2>/dev/null
echo "  ✔ Chapter 41 reset (chai-41-dev and .devcontainer/ removed)."
exit 0
