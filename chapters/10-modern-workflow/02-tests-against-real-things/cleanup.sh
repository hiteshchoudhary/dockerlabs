#!/usr/bin/env bash
# Reset this chapter: remove its throwaway containers (if a run leaked them)
# and the student-written script + report.
docker rm -f chai-42-db chai-42-cache >/dev/null 2>&1
WS="${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}"
rm -f "$WS/ch42/integration.sh" "$WS/ch42/result.txt" 2>/dev/null
echo "  ✔ Chapter 42 reset (chai-42-db, chai-42-cache and ch42 outputs removed)."
exit 0
