#!/usr/bin/env bash
set -uo pipefail
source "${LAB_ROOT:?}/chapters/_lib/assert.sh"

need_docker

if ! docker image inspect chai-09-tool:v1 >/dev/null 2>&1; then
  fail "No image 'chai-09-tool:v1' found. Build it from workspace/ch09: docker build -t chai-09-tool:v1 ."
fi
pass "Image 'chai-09-tool:v1' exists"

ep=$(docker image inspect -f '{{json .Config.Entrypoint}}' chai-09-tool:v1)
cmd=$(docker image inspect -f '{{json .Config.Cmd}}' chai-09-tool:v1)

if [ "$ep" = "null" ] || [ -z "$ep" ]; then
  fail "The image has no ENTRYPOINT. Add one in exec form: ENTRYPOINT [\"/usr/local/bin/greet\"] — then rebuild."
fi
case "$ep" in
  '["/bin/sh","-c",'*) fail "ENTRYPOINT is shell form (inspect shows $ep). Use the JSON-array exec form: ENTRYPOINT [\"/usr/local/bin/greet\"] — then rebuild." ;;
  \[*\]) pass "ENTRYPOINT is exec form: $ep" ;;
  *) fail "ENTRYPOINT looks wrong (inspect shows $ep). Use exec form: ENTRYPOINT [\"/usr/local/bin/greet\"]." ;;
esac

if [ "$cmd" = "null" ] || [ -z "$cmd" ]; then
  fail "The image has no CMD. Add the default argument in exec form: CMD [\"namaste\"] — then rebuild."
fi
case "$cmd" in
  '["/bin/sh","-c",'*) fail "CMD is shell form (inspect shows $cmd). Use the JSON-array exec form: CMD [\"namaste\"] — then rebuild." ;;
  '["namaste"]') pass "CMD is exec form with the default argument: $cmd" ;;
  *) fail "CMD is $cmd — expected exactly [\"namaste\"]. Fix the CMD line and rebuild." ;;
esac

out=$(docker run --rm --name chai-09-probe chai-09-tool:v1 2>&1)
if [ "$out" = "chai says: namaste" ]; then
  pass "No arguments → '$out' (CMD's default kicked in)"
else
  fail "Run with no arguments printed '${out:-nothing}' — expected 'chai says: namaste'. Is the ENTRYPOINT the greet script, and CMD [\"namaste\"]? Check docker run --rm chai-09-tool:v1 yourself."
fi

out=$(docker run --rm --name chai-09-probe chai-09-tool:v1 fresh chai 2>&1)
if [ "$out" = "chai says: fresh chai" ]; then
  pass "With arguments → '$out' (your args replaced the default)"
else
  fail "Run with arguments 'fresh chai' printed '${out:-nothing}' — expected 'chai says: fresh chai'. A shell-form ENTRYPOINT swallows arguments; make sure both lines are exec form and rebuild."
fi

celebrate "Exercise 9.1 complete. You now build images that behave like binaries."
