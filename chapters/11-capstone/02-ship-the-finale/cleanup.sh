#!/usr/bin/env bash
# Reset chapter 46: the registry, the registry-named images, and the deploy
# file. If the chai-45 platform is currently running THIS chapter's registry
# images, take those containers down too (volumes are chapter 45's and stay).
apiref=$(docker container inspect -f '{{.Config.Image}}' chai-45-api 2>/dev/null)
case "$apiref" in
  127.0.0.1:8146/*) docker compose -p chai-45 down --remove-orphans >/dev/null 2>&1 ;;
esac
docker rm -f chai-46-registry >/dev/null 2>&1
docker rmi 127.0.0.1:8146/chai-46-api:1.0.0 127.0.0.1:8146/chai-46-api:1.0.1 \
           127.0.0.1:8146/chai-46-web:1.0.0 >/dev/null 2>&1
rm -f "${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}/ch46/compose.registry.yaml" 2>/dev/null
echo "  ✔ Chapter 46 reset (chai-46-registry, registry-tagged images and compose.registry.yaml removed)."
exit 0
