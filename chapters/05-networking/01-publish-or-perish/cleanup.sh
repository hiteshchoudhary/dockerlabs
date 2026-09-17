#!/usr/bin/env bash
# Reset this chapter: remove only this chapter's containers. Never touches
# anything outside the chai-16- prefix.
docker rm -f chai-16-web chai-16-open chai-16-hidden chai-16-probe >/dev/null 2>&1
echo "  ✔ Chapter 16 reset (chai-16-web, chai-16-open and chai-16-hidden removed)."
exit 0
