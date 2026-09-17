# ChaiCode platform API — zero-dependency Node service.
# Hardened the way Part 8 taught: exec-form CMD, non-root user baked in.
FROM node:22-alpine

WORKDIR /app
ENV NODE_ENV=production

# Build-time version stamp (Chapter 10: ARG for build time, ENV for run time).
# Chapter 46 rebuilds with --build-arg APP_VERSION=1.0.1 to cut a new release.
ARG APP_VERSION=1.0.0
ENV APP_VERSION=$APP_VERSION

COPY server.js .

# Never run as god (Chapter 30). The node base image ships this user.
USER node

EXPOSE 3000
CMD ["node", "server.js"]
