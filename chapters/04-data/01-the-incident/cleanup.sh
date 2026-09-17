#!/usr/bin/env bash
# Reset this chapter: remove only chai-13-* resources and generated workspace files.
docker rm -f chai-13-db >/dev/null 2>&1
docker volume rm chai-13-pgdata >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch13/diff.txt" 2>/dev/null
echo "  ✔ Chapter 13 reset (chai-13-db, chai-13-pgdata, and workspace/ch13 outputs removed)."
exit 0
