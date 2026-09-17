Two `FROM` blocks, one file. Stage 1: `FROM golang:alpine AS build` → `WORKDIR /src` → `COPY go.mod main.go ./` → `RUN CGO_ENABLED=0 go build -o /api .`. Stage 2: `FROM alpine` → `COPY --from=build /api /api` → `CMD ["/api"]`. Build from `ch11/app/`: `docker build -t chai-11-api:slim .`

---

Run: `docker run -d --name chai-11-api -p 8011:3000 chai-11-api:slim`. Over budget? You probably built single-stage (toolchain shipped) — only the *last* `FROM` becomes the image. Container not answering? `docker logs chai-11-api`; the binary must sit where CMD points at it.

---

Challenge: change the build line to `RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /api .` and the final stage to `FROM scratch` + `COPY --from=build /api /api` + `CMD ["/api"]`, then `docker build -t chai-11-api:scratch .` and `docker run -d --name chai-11-mini -p 8111:3000 chai-11-api:scratch`. Editing the Dockerfile doesn't touch the already-built `chai-11-api:slim` — both tags simply coexist.
