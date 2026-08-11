#!/bin/bash
set -e

cd "$(dirname "$0")"

MACHIN="${MACHIN:-machin}"
OUT="${OUT:-tinystats}"

# Encode: framework + app source -> single .mfl
$MACHIN encode \
  framework/machweb.src \
  framework/ws.src \
  src/metrics.src \
  src/server.src \
  src/client.src \
  src/sidecar.src \
  src/app.src \
  > "$OUT.mfl"

# Build native binary
$MACHIN build "$OUT.mfl" -o "$OUT"
chmod +x "$OUT"
echo "built $OUT"
