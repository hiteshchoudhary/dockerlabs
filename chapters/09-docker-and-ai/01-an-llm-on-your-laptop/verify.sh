#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker model status >/dev/null 2>&1; then
  fail "Docker Model Runner isn't answering. Check 'docker model status' — on Docker Desktop, enable Model Runner in Settings → AI, then try again."
fi
pass "Docker Model Runner is running"

if ! docker model list 2>/dev/null | grep -q 'ai/smollm2'; then
  fail "No ai/smollm2 model found in 'docker model list'. Pull it: docker model pull ai/smollm2:135M-Q4_K_M"
fi
pass "Model ai/smollm2 is pulled and listed"

reply="${LAB_WORKSPACE:?}/ch35/reply.txt"
if [ ! -f "$reply" ]; then
  fail "No file at workspace/ch35/reply.txt. Save a one-shot reply: docker model run ai/smollm2:135M-Q4_K_M \"your prompt\" > ./ch35/reply.txt (from workspace/)."
fi
pass "workspace/ch35/reply.txt exists"

chars=$(tr -d '[:space:]' < "$reply" | wc -c | tr -d ' ')
if [ "${chars:-0}" -le 20 ]; then
  fail "reply.txt has only ${chars:-0} characters of text — that's not a real reply. Run the one-shot prompt again and redirect its output into the file."
fi
pass "reply.txt contains a real model reply (${chars} characters)"

celebrate "Exercise 35.1 complete. There is a language model living on your laptop now."
