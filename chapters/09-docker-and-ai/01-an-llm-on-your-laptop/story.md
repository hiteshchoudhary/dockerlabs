# An LLM on Your Laptop

Every AI feature you've seen this decade starts the same way: your data leaves the building. You type a prompt, it travels to someone else's datacenter, runs on someone else's GPU, and the reply comes back with a per-token invoice attached. For a toy demo, fine. But picture the app this Part builds toward — a tutoring service where students paste their homework, their mistakes, their half-finished code. Ship *that* to a third-party API and you've made a data-governance decision, a cost decision, and a latency decision all at once, probably without meaning to.

There's another way, and you already own the tooling: **local inference** — running the model itself on your machine. Three reasons teams do this:

- **Privacy.** The prompt never leaves the machine. For student data, medical notes, proprietary code — sometimes this isn't a preference, it's the law.
- **Cost.** A local model has no meter. Development against a paid API quietly burns money on every test run; development against a local model burns nothing.
- **Latency.** No network round-trip. Small local models often answer faster than a cloud giant, because the wire is gone.

The catch used to be logistics: which runtime, which model file, which flags, which GPU driver. Docker's answer is to treat models the way it treats everything else — as artifacts you `pull` and `run`.

## Docker Model Runner

Docker Desktop ships **Docker Model Runner**, a managed inference engine driven by a new top-level command: `docker model`. First, confirm it's alive:

```
$ docker model status
Docker Model Runner is running
```

Its subcommands will feel familiar on purpose — `pull`, `run`, `list`, `rm`, `inspect`. Models live on Docker Hub under the `ai/` namespace, and tags encode what you're getting: parameter count and quantization. Pull the smallest one that can hold a conversation:

```
$ docker model pull ai/smollm2:135M-Q4_K_M
Downloaded: 100.21 MB
Model ai/smollm2:135M-Q4_K_M pulled successfully
```

One hundred megabytes. That's a complete language model — tiny by LLM standards (frontier models are thousands of times larger), and it will happily hallucinate if you push it. But it demonstrates every mechanic of local inference for the price of an nginx image, and mechanics are what this chapter is about.

```
$ docker model list
MODEL                   PARAMETERS  QUANTIZATION    ARCHITECTURE  SIZE
ai/smollm2:135M-Q4_K_M  134.52 M    IQ2_XXS/Q4_K_M  llama         98.87 MiB
```

Talk to it — one-shot, straight from the CLI:

```
$ docker model run ai/smollm2:135M-Q4_K_M "Say hello in one short sentence."
Hello!
```

No prompt argument drops you into an interactive chat instead. Note what you *didn't* do: no runtime install, no model-file hunting, no GPU driver ceremony. Pull, run, answer.

:::notebook Models are OCI artifacts
When you pulled that model, Docker Hub served it exactly the way it serves images — because it's the same plumbing. A model on Docker Hub is an **OCI artifact**: a manifest plus content-addressed blobs, the format you met in Part 2, just with the model weights as the payload instead of filesystem layers. That's the quiet genius here: registries, tags, digests, `pull`, access control — the entire distribution machinery you already trust for images now ships models too. One artifact store for your whole stack, and "which model is production running?" gets the same answer as "which image?": pin the tag, check the digest.

One honest asymmetry: a model is *not* run as a container. Model Runner hands the weights to a host-side inference engine (llama.cpp under the hood) so it can use your hardware directly — on Apple Silicon that means GPU acceleration via Metal, with no VM in the way. OCI for distribution, native execution for speed.
:::

## The endpoint that matters

The CLI is for you; the **API** is for your software. Model Runner exposes an **OpenAI-compatible** HTTP endpoint — the same `/v1/chat/completions` protocol that has become the de-facto standard of the LLM world. From inside any container, it's reachable at a special DNS name:

```
$ docker run --rm alpine/curl -s \
    http://model-runner.docker.internal/engines/v1/models
{"object":"list","data":[{"id":"ai/smollm2:135M-Q4_K_M","object":"model","owned_by":"docker"}]}
```

`model-runner.docker.internal` is a hostname Docker Desktop resolves *inside containers*, pointing back at the Model Runner on your host — same idea as `host.docker.internal` from Part 5. This is the bridge between the container world and the model world, and it's why the rest of this Part works: any app written against the OpenAI API — which today is nearly every AI app on earth — can be pointed at your laptop by changing one base URL. No SDK swap, no code change. Your code doesn't know the datacenter is gone.

Keep that URL in your pocket; Chapter 37 wires a real service to it.

:::notebook GGUF and quantization, in one paragraph
The weights you pulled are a **GGUF** file — the standard single-file model format of the llama.cpp ecosystem. The `Q4_K_M` in the tag is **quantization**: the model's numbers, trained as 16- or 32-bit floats, stored rounded down to ~4 bits each. That's why 135 million parameters fit in 99 MB instead of ~270 MB at full precision — and why it runs at usable speed on a CPU at all: less memory to move per token means faster tokens. The trade is a small accuracy loss — think JPEG for neural networks. Q4 variants are the sweet spot most local setups use; below Q3 the wheels start visibly coming off.
:::

If you're not on Docker Desktop, the same idea exists one layer up: run **Ollama** in a plain container and you get a comparable local endpoint. Different packaging, same lesson — inference is now just another service on your machine.

Time to make your machine speak.
