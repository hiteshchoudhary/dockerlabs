# Chapter 29 — one Dockerfile, many immutable versions.
# The version is baked in at BUILD time; changing it means building
# a new image with a new tag — never editing a running container.
FROM nginx:alpine
ARG APP_VERSION=dev
RUN echo "chai-29-app version ${APP_VERSION}" > /usr/share/nginx/html/index.html
