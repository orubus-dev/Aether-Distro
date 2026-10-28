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
    lb bootstrap && lb chroot
    # live-build's binary_linux-image exits early with --linux-packages none,
    # so the bootloaders never see a kernel. Copy ours into binary/live
    # (same thing binary_linux-image does with LB_INITRAMFS=live-boot).
    mkdir -p binary/live
    FOUND=0
    for f in chroot/boot/vmlinuz-* chroot/boot/vmlinux-* chroot/boot/initrd.img-*; do
      if [ -e "$f" ]; then cp -a "$f" binary/live/ && FOUND=1; fi
    done
    if [ "$FOUND" != "1" ]; then
      echo "ERROR: no kernel image/initrd in chroot/boot — linux-image-aether deb did not install a kernel?" >&2
      ls -la chroot/boot/ || true
      exit 1
    fi
    ls -la binary/live/
    lb binary
    mkdir -p "$ISO_OUT" && cp -f images/*.iso "$ISO_OUT/" 2>/dev/null || cp -f *.iso "$ISO_OUT/" 2>/dev/null || true
    ;;
  clean) sudo lb clean --purge 2>/dev/null || lb clean --purge || rm -rf chroot .build cache binary images local* ;;
  *) echo "usage: $0 bootstrap|chroot|binary|all|clean"; exit 1 ;;
esac
