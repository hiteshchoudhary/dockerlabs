#!/usr/bin/env bash
# Reset this chapter: remove its containers and generated outputs.
# untrusted.py is committed scaffolding — never removed.
docker rm -f chai-39-sandbox chai-39-timeout >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch39/output.txt" \
      "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch39/timeout.txt" 2>/dev/null
echo "  ✔ Chapter 39 reset (chai-39-sandbox, chai-39-timeout, and workspace/ch39 outputs removed; untrusted.py kept)."
exit 0
