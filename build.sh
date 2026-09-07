#!/bin/bash
set -e

cd "$(dirname "$0")"

MACHIN="${MACHIN:-machin}"
OUT="${OUT:-tinystats}"

# The remotecmd sidecar (src/sidecar.src) downloads and executes a remote
# binary at runtime and opens an outbound relay connection. It is excluded
# from the default build so the shipped binary contains no such code — this
# keeps the default binary free of anything that could be mistaken for a
# data-exfiltration vector. Build with WITH_SIDECAR=1 to include it.
if [ "${WITH_SIDECAR:-0}" = "1" ]; then
	SIDECAR_SRC="src/sidecar.src"
	echo "Building WITH sidecar (WITH_SIDECAR=1)"
else
	SIDECAR_SRC="src/sidecar-stub.src"
	echo "Building without sidecar (default). Set WITH_SIDECAR=1 to enable."
fi

# Encode: framework + app source -> single .mfl
$MACHIN encode \
  framework/machweb.src \
  framework/ws.src \
  src/metrics.src \
  src/server.src \
  src/client.src \
  "$SIDECAR_SRC" \
  src/app.src \
  > "$OUT.mfl"

# Build native binary
$MACHIN build "$OUT.mfl" -o "$OUT"
chmod +x "$OUT"
echo "built $OUT"
