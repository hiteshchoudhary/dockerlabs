#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker container inspect chai-37-api >/dev/null 2>&1; then
  fail "chai-37-api isn't running — finish the main exercise first."
fi

if docker container inspect -f '{{range .Config.Env}}{{println .}}{{end}}' chai-37-api | grep -q '^MODEL_ENDPOINT=.'; then
  pass "MODEL_ENDPOINT is set in the api's environment"
else
  fail "chai-37-api has no MODEL_ENDPOINT env var. Add MODEL_ENDPOINT and MODEL_NAME to the api's environment: in compose.yaml, then docker compose up -d."
fi

body=""
for i in $(seq 1 3); do
  body=$(curl -fsS --max-time 60 'http://127.0.0.1:8037/ask?q=why+use+docker+compose' 2>/dev/null) && break
  sleep 2
done
if [ -z "$body" ]; then
  fail "/ask isn't answering on port 8037. Check: docker compose -p chai-37 logs api"
fi

check=$(node -e '
const j = JSON.parse(process.argv[1]);
if (typeof j.answer === "string" && j.answer.trim().length > 0) { console.log("OK"); process.exit(0); }
console.log(j.model_error ? "ERR:" + j.model_error : "NOANSWER");
' "$body" 2>/dev/null)

case "$check" in
  OK) pass "/ask now includes a model-generated answer — retrieval AND generation, all local" ;;
  ERR:*) fail "The api tried the model and failed: ${check#ERR:}. Is Model Runner up (docker model status) and ai/smollm2:135M-Q4_K_M pulled (Chapter 35)?" ;;
  NOANSWER) fail "/ask has no 'answer' field. Both MODEL_ENDPOINT and MODEL_NAME must be set (see the challenge text), then docker compose up -d to recreate the api." ;;
  *) fail "/ask didn't return valid JSON — check docker compose -p chai-37 logs api." ;;
esac

celebrate "Challenge complete. Full RAG on your laptop — nothing left the machine."
