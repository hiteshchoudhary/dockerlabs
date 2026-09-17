# Challenge

The CLI was the warm-up; software talks to the **endpoint**. From *inside a container*, call Model Runner's OpenAI-compatible chat API and save the raw JSON response to **`workspace/ch35/api-reply.json`**.

The endpoint (reachable from containers only) is:

```
http://model-runner.docker.internal/engines/v1/chat/completions
```

POST a standard OpenAI-style body — `model` set to **`ai/smollm2:135M-Q4_K_M`**, a `messages` array with one user message — using a throwaway curl container (`docker run --rm alpine/curl ...`), and redirect the response to the file.

**You pass when:** `workspace/ch35/api-reply.json` is valid JSON from the smollm2 model with a non-empty `choices[0].message.content` — proof that any OpenAI-API app could run against your laptop.
