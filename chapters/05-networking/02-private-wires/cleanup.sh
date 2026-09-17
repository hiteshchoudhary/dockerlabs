#!/usr/bin/env bash
# Reset this chapter: remove only this chapter's containers and network.
# Never touches anything outside the chai-17- prefix.
docker rm -f chai-17-a chai-17-b chai-17-c >/dev/null 2>&1
docker network rm chai-17-net >/dev/null 2>&1
echo "  ✔ Chapter 17 reset (chai-17-a/b/c and network chai-17-net removed)."
exit 0
