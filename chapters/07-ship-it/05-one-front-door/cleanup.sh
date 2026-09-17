#!/usr/bin/env bash
# Reset this chapter: remove only chai-28-* resources and the generated config copy.
docker rm -f chai-28-proxy chai-28-api1 chai-28-api2 >/dev/null 2>&1
docker network rm chai-28-net >/dev/null 2>&1
docker rmi chai-28-api:1.0 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch28/nginx.conf" 2>/dev/null
echo "  ✔ Chapter 28 reset (chai-28 proxy, replicas, network, image and nginx.conf copy removed)."
exit 0
