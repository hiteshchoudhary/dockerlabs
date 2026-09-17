# ChaiCode web front door — static site + reverse proxy in one image.
# Baking the config and content in (instead of bind-mounting) makes this
# image self-contained: Chapter 46 pushes it to a registry as-is.
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/
