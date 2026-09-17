#!/usr/bin/env bash
# Reset this chapter: remove generated workspace outputs. The mcp/fetch
# image is not chai-owned, so it is left alone (docker rmi mcp/fetch if
# you want the disk back).
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch38/handshake.json" \
      "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch38/mcp-config.json" 2>/dev/null
echo "  ✔ Chapter 38 reset (workspace/ch38 outputs removed; mcp/fetch image kept)."
exit 0
