#!/usr/bin/env bash
# Reset this chapter: remove only chai-15-* resources and generated workspace files.
docker rm -f chai-15-probe >/dev/null 2>&1
docker volume rm chai-15-data chai-15-restore >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch15/backup.tar.gz" 2>/dev/null
echo "  ✔ Chapter 15 reset (chai-15-data, chai-15-restore, and workspace/ch15 outputs removed)."
exit 0
