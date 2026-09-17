The Dockerfile (in `workspace/ch09/`, next to greet.sh): `FROM alpine` → `COPY greet.sh /usr/local/bin/greet` → `RUN chmod +x /usr/local/bin/greet` → `ENTRYPOINT ["/usr/local/bin/greet"]` → `CMD ["namaste"]`. Build with `cd ch09 && docker build -t chai-09-tool:v1 .`

---

If the verifier complains about shell form: `ENTRYPOINT /usr/local/bin/greet` (no brackets) becomes `/bin/sh -c ...` and swallows your arguments. Both lines need JSON arrays — double quotes, comma-separated. Check yourself: `docker image inspect -f '{{json .Config.Entrypoint}} {{json .Config.Cmd}}' chai-09-tool:v1`

---

Challenge: `docker run --name chai-09-peek --entrypoint cat chai-09-tool:v1 /usr/local/bin/greet` — the override (`cat`) goes before the image name, its argument (the file path) after, where CMD's default used to be. Then `docker logs chai-09-peek` shows the script. Rerunning? `docker rm chai-09-peek` first.
