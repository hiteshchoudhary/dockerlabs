# Chapter 43 — build a static Go binary, ship it on nothing at all.

# Stage 1: the builder has a full Go toolchain (~250 MB). It never ships.
FROM golang:alpine AS build
WORKDIR /src
COPY go.mod main.go ./
# CGO_ENABLED=0 => fully static binary: no libc needed, runs on an empty filesystem
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /chai-api .

# Stage 2: scratch is the empty image. No shell, no ls, no cat. Just our binary.
FROM scratch
COPY --from=build /chai-api /chai-api
EXPOSE 8043
ENTRYPOINT ["/chai-api"]
