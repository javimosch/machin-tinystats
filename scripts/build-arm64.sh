#!/bin/bash
# build-arm64.sh — cross-compile the linux/arm64 release asset from an x86_64 host.
#
# machin has no linux-arm64 target flag, but it honours $CC, so this points it at
# a zig cc wrapper. The one real obstacle is OpenSSL: tinystats links libssl and
# libcrypto (machweb pulls in TLS even though tinystats itself speaks plain HTTP),
# and zig ships no aarch64 OpenSSL. Rather than add a foreign dpkg architecture to
# the build host, this unpacks the matching arm64 .debs into a throwaway sysroot.
#
# The headers split across two include paths: openssl/opensslconf.h is
# arch-specific and lives under usr/include/aarch64-linux-gnu, everything else
# under usr/include. Both are needed or the build fails on a missing header.
#
# Requires: zig, curl, dpkg-deb, machin. Output: tinystats-linux-arm64.
set -e
cd "$(dirname "$0")/.."

OPENSSL_VER="${OPENSSL_VER:-3.0.2-0ubuntu1.29}"
OUT="${OUT:-tinystats-linux-arm64}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BASE=http://ports.ubuntu.com/ubuntu-ports/pool/main/o/openssl
for pkg in "libssl3_${OPENSSL_VER}_arm64.deb" "libssl-dev_${OPENSSL_VER}_arm64.deb"; do
	echo "fetching $pkg"
	curl -fsSL -o "$WORK/$pkg" "$BASE/$pkg"
	dpkg-deb -x "$WORK/$pkg" "$WORK/sysroot"
done

SR="$WORK/sysroot"
cat > "$WORK/cc-arm64" <<WRAP
#!/bin/sh
exec ${ZIG:-zig} cc -target aarch64-linux-gnu.2.35 \\
	-I$SR/usr/include/aarch64-linux-gnu \\
	-I$SR/usr/include \\
	-L$SR/usr/lib/aarch64-linux-gnu \\
	-Wl,-s "\$@"
WRAP
chmod +x "$WORK/cc-arm64"

./build.sh >/dev/null   # regenerate tinystats.mfl from src/
CC="$WORK/cc-arm64" machin build tinystats.mfl -o "$OUT"

file "$OUT" | grep -q aarch64 || { echo "not an aarch64 binary"; exit 1; }
echo "built $OUT"
