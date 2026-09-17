#!/usr/bin/env bash
# Reset this chapter: remove only its containers. Images used are stock
# (nginx:alpine, alpine) — never removed.
docker rm -f chai-31-app chai-31-flag >/dev/null 2>&1
echo "  ✔ Chapter 31 reset (chai-31-app and chai-31-flag removed)."
exit 0
