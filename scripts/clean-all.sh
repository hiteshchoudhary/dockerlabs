#!/usr/bin/env bash
# Remove EVERY lab-created Docker resource (all chai-* names) and nothing else.
# Safe by construction: only the chai- prefix is ever touched.
set -uo pipefail

echo "☕ Cleaning all Chai aur Docker lab resources (chai-*)…"

ids=$(docker ps -aq --filter "name=^/chai-" 2>/dev/null)
[ -n "$ids" ] && docker rm -f $ids >/dev/null 2>&1 && echo "  ✔ containers removed"

vols=$(docker volume ls -q --filter "name=^chai-" 2>/dev/null)
[ -n "$vols" ] && docker volume rm -f $vols >/dev/null 2>&1 && echo "  ✔ volumes removed"

nets=$(docker network ls --format '{{.Name}}' | grep '^chai-' 2>/dev/null)
[ -n "$nets" ] && echo "$nets" | xargs -n1 docker network rm >/dev/null 2>&1 && echo "  ✔ networks removed"

imgs=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep '^chai-' 2>/dev/null)
[ -n "$imgs" ] && echo "$imgs" | xargs -n1 docker rmi -f >/dev/null 2>&1 && echo "  ✔ lab images removed"

echo "  Done. Pulled public images (nginx, postgres, …) are kept; remove with 'docker image prune -a' if you want the disk back."
exit 0
