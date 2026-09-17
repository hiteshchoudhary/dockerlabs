# Images Without a Registry

Sooner or later you'll need to move an image to a machine that can't pull it. The classic case is the **air-gapped install**: a customer runs your product on servers with no internet access — banks, hospitals, defense, factories. (Keep this scenario in mind; in Part 7 we ship to exactly such a customer.) But it's also the demo laptop with hotel Wi-Fi, the CI runner behind a paranoid proxy, the quick "just send me the image" between two engineers. Registries are the right answer *most* of the time — and Docker has two built-in escape hatches for the rest. This chapter is about those two, and about the fact that they are **not interchangeable**, despite half the internet using their names as synonyms.

## `docker save` / `docker load`: the whole image, in a file

`docker save` writes an image — the real thing from Chapter 4: manifest, config, every layer — into a single tar archive. `docker load` on any other machine reads it back in:

```
$ docker save chai-06-api:v1 -o chai-06-api.tar
$ ls -lh chai-06-api.tar
-rw-------  1 hitesh  staff    84M  chai-06-api.tar

# ...walk the file over on a USB stick...

$ docker load -i chai-06-api.tar
Loaded image: chai-06-api:v1
```

What arrives is *bit-for-bit the image you had*: same digest, same layers, same history, same config — default command, env vars, exposed ports, all of it. The name and tag come along too. `save` and `load` are lossless; that's the whole point. You can even save several images into one tar (`docker save img1 img2 -o bundle.tar`) and the shared layers are stored once.

:::notebook What's inside the tar
Run `tar -tf` on a saved image and you'll recognize Chapter 4 immediately: an `index.json`, an `oci-layout` marker, and a `blobs/sha256/` directory holding the manifest, the config JSON, and each layer as a content-addressed blob — plus a legacy `manifest.json` so ancient Docker versions can still load it. In other words, `docker save` doesn't invent a format: it writes the standard **OCI image layout**, the same objects a registry would serve, packed into a tar instead of served over HTTP. A registry, a `save` tar, and Docker's local store are three warehouses for the same content-addressed goods — which is why the digest survives the trip.
:::

## `docker export` / `docker import`: a container's filesystem, flattened

The second escape hatch looks similar and is a different thing entirely. `docker export` takes a **container** — not an image — and tars up its *merged filesystem*: the single unified view that OverlayFS presents, everything the container's `/` currently contains, including whatever it wrote into its writable layer.

```
$ docker export chai-06-box -o rootfs.tar
$ docker import rootfs.tar chai-06-flat:v1
```

Notice what that tar is: just files. Not layers — the stack was flattened into one snapshot. Not history — there are no build steps to record. Not config — a filesystem has no opinion about default commands or env vars. `docker import` turns such a tar back into an image, and the result shows all three amputations:

```
$ docker history chai-06-flat:v1
IMAGE          CREATED          CREATED BY   SIZE    COMMENT
dadcffab386c   10 seconds ago                80MB    Imported from -
```

One layer. One history row, and it says nothing. Compare that with the original image's twenty-row construction story from Chapter 5. And because the config is gone, running the imported image means re-specifying everything by hand (`docker run chai-06-flat:v1 nginx -g 'daemon off;'` — you have to *know* that). Your challenge below measures this loss precisely.

## So which one, when?

The rule is short: **moving images → `save`/`load`. Rescuing or flattening a container's filesystem → `export`/`import`.**

- Shipping your app to the air-gapped customer? `save`/`load` — you want the config and the layers.
- Grabbing the current filesystem of a container for forensics, or deliberately squashing a lineage of layers into one? `export`/`import` — flattening is the *feature*.
- Tempted to use `export` to ship an app because the tar is a bit smaller? You just amputated the image's config and history to save a few megabytes. Don't.

One symmetry worth noticing: `commit` (last chapter) and `export` both start from a container — but `commit` *preserves* the layer stack and adds one, while `export` *collapses* it. And neither replaces a registry for daily work: tars on USB sticks don't do tags, access control, or `Already exists` deduplication between machines. Part 7 gives you a real registry; this chapter is your fallback when there can't be one.

:::notebook Why load restores the digest but import never can
`load` ingests content-addressed blobs unchanged, so every hash — layer digests, manifest digest — comes out exactly as it went in; the image is *verifiably* the one you saved. `import` instead receives an anonymous pile of files, gzips it into a brand-new layer blob, and wraps a brand-new minimal config around it — new hashes never seen before, unconnected to any ancestry. That's also a supply-chain observation (Part 8 territory): a loaded image can be traced and verified against what was published; an imported one is a fresh artifact whose past exists only in someone's memory.
:::

Time to run the round-trip yourself: pack an image into a tar, destroy the local copy, resurrect it — then measure exactly what `export` throws away.
