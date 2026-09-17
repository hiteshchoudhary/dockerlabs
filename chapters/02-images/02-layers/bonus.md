# Challenge

The chapter claims `chai-05-snapshot:v1` and `alpine` physically share their base layer on disk. Don't believe it — prove it.

Compare the two images' layer digest lists (the `.RootFS.Layers` field from `docker image inspect` — a format template will serve you well here). Find every digest that appears in **both** lists, and write those shared digests into **`workspace/ch05/shared-layers.txt`** (one per line; from the lab terminal in `workspace/`, that's `./ch05/shared-layers.txt`).

Same digest in both lists = same content-addressed blob = stored once, shared by both images.

**You pass when:** `workspace/ch05/shared-layers.txt` contains exactly the layer digests common to `chai-05-snapshot:v1` and `alpine` — no more, no fewer (the verifier computes the intersection itself and compares).
