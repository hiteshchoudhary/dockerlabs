#!/usr/bin/env bash
# Reset this chapter: remove only chai-24-* resources.
docker rm -f chai-24-registry >/dev/null 2>&1
docker rmi chai-24-api:1.0 chai-24-api:roundtrip 127.0.0.1:8124/chai-24-api:1.0 >/dev/null 2>&1
echo "  ✔ Chapter 24 reset (chai-24-registry and chai-24-api images removed)."
exit 0
