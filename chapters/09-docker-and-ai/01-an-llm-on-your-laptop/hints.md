`docker model run` takes the model name and then an optional prompt in quotes — with a prompt it answers once and exits (perfect for redirecting to a file); without one it drops you into an interactive chat. Saving any command's output to a file is plain shell: `command > file`.

---

From `workspace/`: `mkdir -p ch35 && docker model run ai/smollm2:135M-Q4_K_M "your prompt here" > ./ch35/reply.txt`. Check what landed with `cat ./ch35/reply.txt` — if it's empty, run it again without the redirect to see what's happening.

---

Challenge: the request must come from *inside* a container (that's where `model-runner.docker.internal` resolves). From `workspace/`:
```
docker run --rm alpine/curl -s http://model-runner.docker.internal/engines/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"ai/smollm2:135M-Q4_K_M","messages":[{"role":"user","content":"Why is chai great? One sentence."}]}' \
  > ./ch35/api-reply.json
```
