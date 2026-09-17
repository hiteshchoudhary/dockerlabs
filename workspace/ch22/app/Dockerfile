# Scaffolded for Chapter 22 — deps-first ordering from Chapter 8.
FROM node:22-alpine
WORKDIR /usr/src/app
COPY package.json ./
# (real apps run `npm ci` here — this one has zero dependencies)
COPY server.js ./
COPY public ./public
EXPOSE 3000
CMD ["node", "server.js"]
