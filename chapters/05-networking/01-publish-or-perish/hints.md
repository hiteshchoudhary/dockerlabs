The `-p` flag has a long form: `-p HOSTIP:HOSTPORT:CONTAINERPORT`. Leave the `HOSTIP:` part off and Docker binds `0.0.0.0` (all interfaces). nginx listens on port 80 *inside* the container — that's always the right-hand number.

---

The loopback one: `docker run -d --name chai-16-web -p 127.0.0.1:8016:80 nginx:alpine`. Check what you built with `docker port chai-16-web` or `docker ps`. If a name is already taken from an earlier attempt, remove it first: `docker rm -f chai-16-web`.

---

Full commands: `docker run -d --name chai-16-open -p 8116:80 nginx:alpine` for the open one, and for the challenge simply `docker run -d --name chai-16-hidden nginx:alpine` — no `-p` at all. That's the whole point: `EXPOSE 80` in the image changes nothing at runtime.
