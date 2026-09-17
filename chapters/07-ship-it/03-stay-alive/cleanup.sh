#!/usr/bin/env bash
# Reset this chapter: remove only chai-26-* containers.
docker rm -f chai-26-app chai-26-oom >/dev/null 2>&1
echo "  ✔ Chapter 26 reset (chai-26-app and chai-26-oom removed)."
exit 0
