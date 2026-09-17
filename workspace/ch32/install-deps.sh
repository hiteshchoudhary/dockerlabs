#!/bin/sh
# Simulates installing packages from a private registry: refuses to run
# without an API token, and records a fingerprint (sha256) of the token it
# was given — proof, later, that the secret really was present at build time.
set -e

TOKEN_FILE="/run/secrets/apitoken"

if [ ! -s "$TOKEN_FILE" ]; then
  echo "FATAL: no API token at $TOKEN_FILE — private registry unreachable." >&2
  echo "       Mount it for this step only: RUN --mount=type=secret,id=apitoken sh ./install-deps.sh" >&2
  exit 1
fi

echo "token accepted — installing private packages..."
sha256sum "$TOKEN_FILE" | cut -d' ' -f1 > /app/token.fingerprint
echo "done. fingerprint recorded at /app/token.fingerprint"
