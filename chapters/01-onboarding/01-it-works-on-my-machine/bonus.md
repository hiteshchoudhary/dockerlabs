# Challenge

`hello-world` runs whatever its image tells it to. Now make a container run what *you* tell it to — that's the difference between using containers and driving them.

Run a container from the **`alpine`** image (a ~5 MB Linux — the smallest useful base image there is), name it **`chai-01-echo`**, and make it print exactly:

```
hello chaicode
```

Then — after it has exited — use `docker logs` to read what it printed. That's how you inspect the output of any container, including one that finished long ago: the daemon keeps each container's stdout until the container is removed.

**You pass when:** a container named `chai-01-echo` exists, was created from `alpine`, and its logs contain `hello chaicode`.
