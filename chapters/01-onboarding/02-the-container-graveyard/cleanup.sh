#!/usr/bin/env bash
# Reset this chapter: remove only this chapter's containers.
docker rm -f chai-02-web chai-02-junk chai-02-crash >/dev/null 2>&1
echo "  ✔ Chapter 2 reset (chai-02-web, chai-02-junk, chai-02-crash removed)."
exit 0
