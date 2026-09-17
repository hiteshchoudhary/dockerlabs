# Chapter 25 — each platform build runs RUN under that platform's CPU
# (emulated by QEMU where needed), so the baked file names the architecture
# the layer was built for.
FROM alpine
RUN uname -m > /arch.txt
CMD ["cat", "/arch.txt"]
