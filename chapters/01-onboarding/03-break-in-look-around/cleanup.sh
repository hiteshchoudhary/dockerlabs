#!/usr/bin/env bash
# Reset this chapter: remove its container and generated workspace files.
docker rm -f chai-03-box >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch03/status.txt" \
      "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch03/ip.txt" 2>/dev/null
echo "  ✔ Chapter 3 reset (chai-03-box and workspace/ch03 outputs removed)."
exit 0
