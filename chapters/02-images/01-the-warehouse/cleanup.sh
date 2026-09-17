#!/usr/bin/env bash
# Reset this chapter: remove its container, its retag, and generated
# workspace files. Never touches the pulled nginx images or anything
# outside the chai-04- prefix.
docker rm -f chai-04-digest >/dev/null 2>&1
docker rmi chai-04-api:pinned >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch04/digest.txt" 2>/dev/null
echo "  ✔ Chapter 4 reset (chai-04-digest, chai-04-api:pinned and workspace/ch04 outputs removed)."
exit 0
