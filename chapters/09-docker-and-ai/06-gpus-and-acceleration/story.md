# GPUs & Acceleration

A field-notes chapter, and an honest one. Serious model inference and all model *training* run on **GPUs** — thousands of small cores doing the massively parallel matrix math neural networks are built from. A CPU has a few big cores optimized for sequential work; a GPU has thousands of small ones optimized for doing the same operation across a huge array at once, which is exactly what a forward pass through a transformer is. So the question every AI-infra engineer eventually asks: how does a *container* — an isolated process — reach the GPU?

This machine is Apple Silicon and has no NVIDIA GPU, so we can't run the CUDA path here. That's the whole point of this chapter: you'll learn the commands and the mental model precisely so you're not learning them for the first time on a cloud GPU box that bills by the minute. The exercise verifies what your machine *actually* reports; the challenge has you write the command you'd run *there*.

## The NVIDIA path (Linux + NVIDIA GPU)

By default a container sees no GPU — the device nodes and driver libraries simply aren't in its world. On a Linux host with an NVIDIA card you install the **NVIDIA Container Toolkit**, which registers a container **runtime** (`nvidia`) that, at container start, injects the GPU device nodes and the matching userspace driver libraries into the container. Then one flag lights it up:

```
# on a Linux box with NVIDIA GPU + Container Toolkit installed:
$ docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 550.x    Driver Version: 550.x    CUDA Version: 12.4             |
|   0  NVIDIA A100-SXM4-40GB   ...                                            |
+-----------------------------------------------------------------------------+
```

`--gpus all` exposes every GPU; `--gpus '"device=0,1"'` picks specific ones; `--gpus 2` grants a count. `nvidia-smi` printing a table *from inside the container* is the "it works" moment — the containerized process is talking to real silicon.

The container image still needs CUDA userspace libraries (hence the `nvidia/cuda` base or a framework image built on it), but — and this is the elegant part — **not the driver**. The host owns the driver; the toolkit injects it at runtime. That separation is why one GPU image runs across host driver versions.

:::notebook How `--gpus` actually reaches the hardware
The `--gpus` flag isn't magic; it's a request the **NVIDIA Container Toolkit** fulfils through a container hook. At startup the toolkit's `nvidia-container-runtime` (a thin shim around `runc`) runs a prestart hook that bind-mounts the GPU device files (`/dev/nvidia*`) into the container and mounts the host's driver libraries (`libcuda.so` and friends) to match. The kernel driver stays on the host — shared, exactly like the kernel itself (Chapter 39's boundary). So a "GPU container" isn't virtualizing a GPU; it's a normal container that's been handed direct, bind-mounted access to the host's real device. That's why GPU passthrough is near-zero overhead — and also why it's Linux-only: it leans on Linux device files and the NVIDIA kernel driver, neither of which exists in Docker Desktop's Mac/Windows VM.
:::

## What Apple Silicon does instead

On a Mac, Docker Desktop runs your containers inside a **lightweight Linux VM**, and that VM has no passthrough to the Mac's GPU. So `--gpus all` inside a Linux container on this machine reaches nothing — there is no `nvidia` runtime to satisfy it. Run `docker info` and you'll see the truth: the runtimes are `runc` and `io.containerd.runc.v2`. No `nvidia`. That's not a misconfiguration; it's the platform.

So how did smollm2 feel fast in Chapter 35? Because **Docker Model Runner doesn't run the model in a container** — it runs it as a *host-native* process (llama.cpp), which reaches the Apple GPU directly through **Metal**, Apple's graphics/compute API. That's the deliberate architecture choice from Chapter 35 paying off: OCI artifacts for distribution, native execution for acceleration. The model gets the GPU; it just doesn't get it *through a container*, because on this platform it can't.

And when there's no GPU at all — CI runners, small VMs, this Mac for anything outside Model Runner — inference falls back to the **CPU**, which is where Chapter 35's quantization stops being trivia. A `Q4` model moves a quarter of the memory per token versus full precision, and on a CPU, memory bandwidth is the bottleneck. Quantization is what makes CPU inference merely *slow* instead of *unusable*. It's the reason a 135M model answers on your laptop at all.

## The honest summary

- **NVIDIA GPU on Linux** → NVIDIA Container Toolkit + `--gpus all`. The production path for real inference and all training.
- **Apple Silicon** → no container GPU passthrough; host-native Metal via Model Runner; containers themselves run CPU-only.
- **No GPU** → CPU inference, made survivable by quantization; fine for small models and development.

Know which world you're in before you write the `docker run`. The exercise makes your machine tell you, in its own words.
