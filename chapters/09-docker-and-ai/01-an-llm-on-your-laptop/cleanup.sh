#!/usr/bin/env bash
# Reset this chapter: remove generated workspace outputs ONLY.
# The pulled model is intentionally KEPT (later chapters reuse it and
# nobody wants to re-download 100 MB) — remove it yourself with
# 'docker model rm ai/smollm2:135M-Q4_K_M' if you really want it gone.
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch35/reply.txt" \
      "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch35/api-reply.json" 2>/dev/null
echo "  ✔ Chapter 35 reset (workspace/ch35 outputs removed; the ai/smollm2 model is kept on purpose)."
exit 0
