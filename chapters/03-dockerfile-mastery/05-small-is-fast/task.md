# Exercise

**11.1 — Multi-stage build: ship the binary, discard the workshop.**

1. Look at `workspace/ch11/app/` — the ChaiCode API in Go (`main.go`, `go.mod`), answering JSON on port `3000`. No Go on your machine required.
2. Create a `Dockerfile` there with **two stages**:
   - a build stage `FROM golang:alpine AS build` that copies `go.mod` + `main.go` and compiles a static binary (`CGO_ENABLED=0 go build -o /api .`),
   - a final stage `FROM alpine` that does nothing but `COPY --from=build` the binary and set an exec-form `CMD`.
3. Build it as **`chai-11-api:slim`**.
4. Run a detached container named **`chai-11-api`** publishing host port **`8011`** to container port `3000`, and curl it.
5. Weigh your work: `docker image inspect -f '{{.Size}}' chai-11-api:slim` — that exact number is what's graded.

**You pass when:**

- Image **`chai-11-api:slim`** exists and weighs in **under 20 MB** by `docker image inspect -f '{{.Size}}'` (a clean two-stage build lands well under — being over means a stage leaked into the ship).
- Container **`chai-11-api`** is running from it.
- `http://localhost:8011` answers the ChaiCode API's JSON, with `"lang":"go"` as proof of the rewrite.

The verifier puts the image on the scale and curls the container — how many stages you used to get there is your business (but one won't fit the budget).
