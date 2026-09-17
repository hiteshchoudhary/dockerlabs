#!/usr/bin/env bash
# Reset this chapter: remove generated workspace outputs. No containers,
# images, or volumes are created by this chapter.
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch40/runtimes.txt" \
      "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch40/nvidia.txt" \
      "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch40/gpu-run.txt" 2>/dev/null
echo "  ✔ Chapter 40 reset (workspace/ch40 outputs removed)."
exit 0
