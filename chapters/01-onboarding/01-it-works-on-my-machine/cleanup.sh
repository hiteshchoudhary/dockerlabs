#!/usr/bin/env bash
# Reset this chapter: remove only this chapter's containers. Never touches
# anything outside the chai- prefix.
docker rm -f chai-01-hello chai-01-echo >/dev/null 2>&1
echo "  ✔ Episode 1 reset (chai-01-hello and chai-01-echo removed)."
exit 0
