# Exercise

**6.1 — Ship an image with no registry: the save/load round-trip.**

1. **Create your release artifact.** Retag `nginx:alpine` (Chapter 4 skill — instant, no copy) as **`chai-06-api:v1`**. That's the image "the customer" is buying.
2. **Pack it:** `docker save` it into a tar at **`workspace/ch06/chai-06-api.tar`** (the lab terminal opens in `workspace/`, so `./ch06/chai-06-api.tar`; create the folder if needed). Peek inside with `tar -tf` — you'll recognize the blobs from Chapter 4.
3. **Simulate the air gap:** remove the image name from your machine with `docker rmi chai-06-api:v1`. Confirm `docker images` no longer lists it — as far as that name is concerned, you're now the customer's offline server.
4. **Resurrect it:** `docker load` the tar back in, and confirm `chai-06-api:v1` is listed again.

The verifier checks the two ends of the trip — the tar on disk *and* the image name present — which together are exactly what "the round-trip works" means; it can't see (and doesn't care) how the bytes traveled in between.

**You pass when:**

- **`workspace/ch06/chai-06-api.tar`** exists and is a genuine image archive (it must contain an image manifest naming `chai-06-api`).
- The image **`chai-06-api:v1`** is present locally.
