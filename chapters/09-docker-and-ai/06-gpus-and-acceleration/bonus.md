# Challenge

You won't run a GPU container on this Mac — but you must be able to *write the command cold*, because the day you SSH into a rented Linux GPU box, the meter is running.

Write to **`workspace/ch40/gpu-run.txt`** the exact `docker run` command you would use to run `nvidia-smi` inside a CUDA container with **all** GPUs exposed. It must include:

- `docker run`
- the `--gpus all` flag
- a CUDA image (something with `nvidia/cuda` in its name)
- the `nvidia-smi` command at the end

This is a static check — the verifier reads the command string and confirms the flags are correct. Nothing runs (there's no GPU to run it on); you're proving you know the incantation before you need it.

**You pass when:** `workspace/ch40/gpu-run.txt` contains a single `docker run` command with `--gpus all`, an `nvidia/cuda` image, and `nvidia-smi`.
