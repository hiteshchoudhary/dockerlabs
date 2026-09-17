# Challenge

An image is a class; containers are its objects — Chapter 1's claim, never yet proven with an image of your own.

Prove it now: from the same **`chai-07-api:v1`** image, run a **second** detached container named **`chai-07-copy`**, publishing host port **`8107`** to container port `3000`. No rebuild, no copy of anything — one frozen artifact, two independent running instances.

Then curl both ports and compare the `hostname` field in the JSON: each container gets its own hostname (it's the container ID — that's the UTS namespace from Chapter 1 showing through).

**You pass when:** `chai-07-copy` is running from the same image as `chai-07-api`, and `http://localhost:8107` answers with the ChaiCode API's JSON.
