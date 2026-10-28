#!/bin/bash
# AetherOS kernel build — compiles Linux from kernel.org source with the Aether config.
# No distro kernel ships in AetherOS; this is the only kernel in the ISO.
# Output: dist/linux-image-aether_<ver>_amd64.deb  (+ recorded .config)
set -euo pipefail
cd "$(dirname "$0")/../.."
ROOT="$PWD"; FRAG="$ROOT/02-kernel/aether-x86_64.config"; OUT="$ROOT/dist"; mkdir -p "$OUT"

VER="${AETHER_KERNEL_VER:-$(curl -fsSL https://cdn.kernel.org/pub/linux/kernel/v6.x/ | grep -oP 'linux-6\.12\.\d+\.tar\.xz' | sort -V | tail -1 | grep -oP '6\.12\.\d+')}"
echo "[aether-kernel] building Linux $VER"
WORK="$ROOT/build/kernel/linux-$VER"
if [ ! -d "$WORK" ]; then
  curl -fsSL -o /tmp/aether-kernel.tar.xz "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$VER.tar.xz"
  mkdir -p "$WORK"; tar -xf /tmp/aether-kernel.tar.xz -C "$WORK" --strip-components=1; rm -f /tmp/aether-kernel.tar.xz
fi
cd "$WORK"

if [ ! -f .config ] || [ "$FRAG" -nt .config ]; then
  make x86_64_defconfig
  scripts/kconfig/merge_config.sh -m .config "$FRAG"
  make olddefconfig
  python3 - "$FRAG" <<'EOF'
import re,sys
frag={}
for line in open(sys.argv[1]):
    line=line.strip()
    if line.startswith('CONFIG_') and '=' in line:
        k,v=line.split('=',1); frag[k]=v
final=dict(re.findall(r'^(CONFIG_[A-Z0-9_]+)=(.*)$', open('.config').read(), re.M))
unset_ok=[k for k,v in frag.items() if v in ('n','""')]
missing=[(k,v) for k,v in frag.items() if k not in final and k not in unset_ok]
wrong=[(k,v,final.get(k)) for k,v in frag.items() if k in final and final[k]!=v and k not in unset_ok]
if missing or wrong:
    print("KERNEL CONFIG FAIL — missing:",missing,"mismatch:",wrong); sys.exit(1)
print(f"[aether-kernel] config OK: all {len(frag)} fragment symbols resolved")
EOF
fi
cp .config "$OUT/config-$VER-aether"

JOBS="${AETHER_KERNEL_JOBS:-$(nproc)}"
# kernel's generated debian/control wants debhelper-compat (= 12); trixie only ships (= 13).
# Provide it with a versioned-Provides dummy (same mechanism debhelper itself uses), plus real kmod.
if ! dpkg -s debhelper-compat-dummy >/dev/null 2>&1; then
  D=/tmp/dhc12; rm -rf "$D" /tmp/dhc12.deb; mkdir -p "$D/DEBIAN"
  printf 'Package: debhelper-compat-dummy\nVersion: 1.0\nSection: devel\nPriority: optional\nArchitecture: all\nProvides: debhelper-compat (= 12)\nDescription: satisfies linux bindeb-pkg build-dependency\n' > "$D/DEBIAN/control"
  dpkg-deb --build "$D" /tmp/dhc12.deb >/dev/null && dpkg -i /tmp/dhc12.deb >/dev/null
  apt-get install -y kmod >/dev/null 2>&1 || true
fi
make -j"$JOBS" bindeb-pkg >/tmp/aether-kernel-build.log 2>&1 || { tail -30 /tmp/aether-kernel-build.log; exit 1; }
echo "[aether-kernel] compiled"

# Repackage as linux-image-aether so live-build --linux-packages none + local deb flow works
IMG_DEB=$(ls -t "$ROOT/build/kernel"/linux-image-*.deb 2>/dev/null | head -1 || true)
echo "[aether-kernel] deb at: $IMG_DEB"
PKG="$ROOT/build/kernel/pkg"; rm -rf "$PKG"; mkdir -p "$PKG"
dpkg-deb -R "$IMG_DEB" "$PKG"
sed -i 's/^Package: .*/Package: linux-image-aether/; s/^Version: .*/Version: 1.0.0/; s/^Depends: .*/Depends: linux-base, initramfs-tools | linux-initramfs-tool/; /Provides:/d' "$PKG/DEBIAN/control"
grep -q "^Provides:" "$PKG/DEBIAN/control" || sed -i '/^Depends:/a Provides: linux-image' "$PKG/DEBIAN/control"
dpkg-deb -b "$PKG" "$OUT/linux-image-aether_1.0.0_amd64.deb" >/dev/null
echo "[aether-kernel] DONE: $OUT/linux-image-aether_1.0.0_amd64.deb"
