# Challenge

Time to trust the volume. Destroy the container — **`docker rm -f chai-36-qdrant`** — then start a **brand-new** container with the same name, same port, and the **same `chai-36-data` volume**.

Query the collection again: your points must still be there, served by a container that didn't exist a minute ago. Then write the surviving point count (just the number) to **`workspace/ch36/survived.txt`**.

**You pass when:** the running `chai-36-qdrant` container is demonstrably *newer* than the `chai-36-data` volume (a replacement, not the original), the collection still holds your points, and `survived.txt` states the correct live count.
