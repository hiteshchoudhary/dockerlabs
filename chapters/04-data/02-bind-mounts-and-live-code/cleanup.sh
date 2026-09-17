#!/usr/bin/env bash
# Reset this chapter: remove its container and restore the committed scaffold
# (students edit workspace/ch14/site/index.html as part of the exercise).
docker rm -f chai-14-web >/dev/null 2>&1

WS="${LAB_WORKSPACE:-$(dirname "$0")/../../../workspace}"
mkdir -p "$WS/ch14/site"
cat > "$WS/ch14/site/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>chai-14-web</title>
    <style>
      body { font-family: system-ui, sans-serif; max-width: 40rem; margin: 4rem auto; }
      h1 { color: #b45309; }
    </style>
  </head>
  <body>
    <h1>Chai aur Docker — served live from a bind mount</h1>
    <p id="marker">edit me</p>
    <p>Change this file on your host, refresh (or re-curl), and the container serves the new bytes instantly. No rebuild. No restart.</p>
  </body>
</html>
EOF

echo "  ✔ Chapter 14 reset (chai-14-web removed, ch14/site/index.html scaffold restored)."
exit 0
