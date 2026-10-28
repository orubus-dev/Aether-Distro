#!/bin/bash
# AetherOS distro assembly (live-build). Stages are resumable:
#   ./build.sh bootstrap | chroot | binary | all
set -euo pipefail
cd "$(dirname "$0")"
STAGE="${1:-all}"

# install our kernel + local packages, then assemble
export ISO_OUT="$(dirname "$0")/../../dist"

case "$STAGE" in
  bootstrap) chmod +x auto/config && ./auto/config && lb bootstrap ;;
  chroot)    lb chroot ;;
  binary)    lb binary ;;
  all)
    chmod +x auto/config
    [ -f config/packages.chroot/linux-image-aether_*.deb ] || { echo "kernel deb missing — run build/kernel/build.sh first"; exit 1; }
    ./auto/config
    lb bootstrap && lb chroot && lb binary
    mkdir -p "$ISO_OUT" && cp -f images/*.iso "$ISO_OUT/" 2>/dev/null || cp -f *.iso "$ISO_OUT/" 2>/dev/null || true
    ;;
  clean) sudo lb clean --purge 2>/dev/null || lb clean --purge || rm -rf chroot .build cache binary images local* ;;
  *) echo "usage: $0 bootstrap|chroot|binary|all|clean"; exit 1 ;;
esac
