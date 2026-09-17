#!/usr/bin/env bash
# Reset this chapter: remove only this chapter's containers and network.
# Never touches anything outside the chai-18- prefix.
docker rm -f chai-18-db chai-18-cache chai-18-api chai-18-lonely >/dev/null 2>&1
docker network rm chai-18-net >/dev/null 2>&1
echo "  ✔ Chapter 18 reset (chai-18-db/cache/api/lonely and network chai-18-net removed)."
exit 0
