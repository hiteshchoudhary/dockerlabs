#!/usr/bin/env bash
# Reset this chapter: remove its container and generated workspace output.
docker rm -f chai-27-app >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch27/events.txt" 2>/dev/null
echo "  ✔ Chapter 27 reset (chai-27-app and workspace/ch27 outputs removed)."
exit 0
