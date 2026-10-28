#!/bin/bash
# AetherOS distro assembly (live-build). Stages are resumable:
#   ./build.sh bootstrap | chroot | binary | all
set -euo pipefail
# Resolve the script's directory BEFORE any cd: $0-relative paths break once
# we cd. Absolute BUILD_DIR + ISO_OUT; a relative ISO_OUT previously resolved
# against build/distro (and an empty `export V=$(false-cd)` substitution even
# made it literal "/dist" — export masks substitution failure under set -e).
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
cd "$BUILD_DIR"
STAGE="${1:-all}"

# install our kernel + local packages, then assemble
export ISO_OUT="$(cd "$BUILD_DIR/../.." && pwd)/dist"

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
    mkdir -p "$ISO_OUT"
    # live-build writes the ISO into its CWD (build/distro): find it wherever
    # it landed and copy every *.iso into $ISO_OUT, then FAIL if none exists.
    find . config images -maxdepth 2 -name '*.iso' -type f -exec cp -f {} "$ISO_OUT/" \; 2>/dev/null || true
    ls -la "$ISO_OUT/"
    if ! ls "$ISO_OUT"/*.iso >/dev/null 2>&1; then
      echo "ERROR: no ISO produced by lb binary" >&2
      find . -maxdepth 2 -name '*.iso' -o -name '*.hybrid.iso' 2>/dev/null || true
      exit 1
    fi
    sha256sum "$ISO_OUT"/*.iso | tee "$ISO_OUT/SHA256SUMS"
    ;;
  clean) sudo lb clean --purge 2>/dev/null || lb clean --purge || rm -rf chroot .build cache binary images local* ;;
  *) echo "usage: $0 bootstrap|chroot|binary|all|clean"; exit 1 ;;
esac
