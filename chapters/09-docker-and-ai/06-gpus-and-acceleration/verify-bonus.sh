#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

# Static check only — nothing runs (no GPU on this platform).
f="${LAB_WORKSPACE:?}/ch40/gpu-run.txt"
if [ ! -f "$f" ]; then
  fail "No file at workspace/ch40/gpu-run.txt. Write the docker run command you'd use on a GPU box (see the challenge)."
fi
pass "workspace/ch40/gpu-run.txt exists"

cmd=$(cat "$f")

echo "$cmd" | grep -Eq 'docker[[:space:]]+run' \
  || fail "The command must start a container with 'docker run'. Found: $cmd"
pass "It's a 'docker run' command"

echo "$cmd" | grep -Eq -- '--gpus[[:space:]=]+all' \
  || fail "Missing '--gpus all' — that's the flag that exposes every GPU to the container."
pass "Exposes all GPUs with --gpus all"

echo "$cmd" | grep -Eq 'nvidia/cuda' \
  || fail "The image should be a CUDA image (nvidia/cuda...), which ships the CUDA userspace libraries."
pass "Uses an nvidia/cuda image"

echo "$cmd" | grep -Eq 'nvidia-smi' \
  || fail "End the command with 'nvidia-smi' — printing that table from inside the container is the proof it worked."
pass "Runs nvidia-smi inside the container"

celebrate "Challenge complete. When you meet a real GPU, the command is already muscle memory."
