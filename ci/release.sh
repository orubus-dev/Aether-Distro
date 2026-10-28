#!/bin/bash
# ci/release.sh — attach the ISO to the GitHub Release for this tag.
# GitHub caps release assets at 2 GiB; a full Plasma+Wine desktop ISO is ~2.7 GiB,
# so if the ISO exceeds the cap it ships as <=2GiB parts + a one-line join command.
# Idempotent: existing assets are skipped, so a re-run resumes instead of failing.
set -euo pipefail
API="https://api.github.com"
AUTH="Authorization: token $GH_TOKEN"
ISO=$(ls dist/*.iso | head -1)
# ship under a human name instead of live-image-amd64.hybrid.iso
DISP="AetherOS-1.0-amd64.iso"
[ "$(basename "$ISO")" = "$DISP" ] || cp -f "$ISO" "dist/$DISP"
ISO="dist/$DISP"
NAME="$DISP"
SHA=$(sha256sum "$ISO" | cut -d' ' -f1)
SIZE=$(stat -c%s "$ISO")
CAP=2147483648   # GitHub release-asset cap (2 GiB)

REL=$(curl -fsS -H "$AUTH" "$API/repos/$REPO/releases/tags/$TAG" 2>/dev/null || true)
if [ -z "$REL" ]; then
  REL=$(curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"tag_name\":\"$TAG\",\"name\":\"AetherOS $TAG (Nebula)\",\"body\":\"releasing\"}" \
    "$API/repos/$REPO/releases")
fi
REL_ID=$(echo "$REL" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
UPLOAD_URL=$(echo "$REL" | python3 -c "import json,sys; print(json.load(sys.stdin)['upload_url'].split('{')[0])")
have() { echo "$REL" | grep -q "\"name\": \"$1\""; }
upload() {
  echo "uploading $2 ($(stat -c%s "$1") bytes)..."
  curl -fS -X POST -H "$AUTH" -H "Content-Type: application/octet-stream" \
    --data-binary @"$1" "$UPLOAD_URL?name=$2" -o /dev/null
}

JOINS=""
if [ "$SIZE" -le "$CAP" ]; then
  have "$NAME" || upload "$ISO" "$NAME"
else
  split -b 1900m -d "$ISO" "$NAME.part-"
  for P in "$NAME".part-*; do
    have "$(basename "$P")" || upload "$P" "$(basename "$P")"
  done
  JOINS="## Download \u0026 join (GitHub caps release files at 2 GiB)
- Download ALL \`$NAME.part-*\` assets into the same folder
- Join on any Linux/Mac/Termux: \`cat $NAME.part-* > $NAME\`
- Join on Windows: \`copy /b $NAME.part-00+$NAME.part-01 $NAME\`
- Verify the SHA256 below, then copy the joined ISO onto your (Ventoy) stick"
fi

have "SHA256SUMS.txt" || { upload dist/SHA256SUMS.txt "SHA256SUMS.txt" || true; }

ARTLINE=""
[ -n "${ARTIFACT_URL:-}" ] && ARTLINE="- **Single-file download (no joining):** $ARTIFACT_URL (Actions artifact, needs GitHub login, expires in 90 days)\n"

BODY=$(printf '%s' "AetherOS $TAG (Nebula) — bootable release. Smoke-boot-verified in CI: kernel, initramfs, live system all come up.

## What's inside
- AetherOS kernel compiled from kernel.org source (gaming-tuned: 1000Hz, full preemption, binderfs, zram)
- Plasma 6 Wayland desktop, macOS-style layout (menu bar + floating dock, WhiteSur)
- Wine (Windows apps), Waydroid (Android apps), Steam + gamemode + MangoHud
- Calamares installer; UEFI + Legacy boot; Debian 13 (trixie) floor

## No-flash quick start
- **Zero flashing, forever:** install Ventoy on a USB stick ONCE (2 min, https://www.ventoy.net) — after that every ISO is just a file you copy onto the stick and boot
- **From your phone:** download the ISO here → copy it to the Ventoy stick via USB-OTG → boot any PC
- **No USB at all:** open the ISO in VirtualBox/VMware and it boots
- Full guide: docs/NO-FLASH-START.md in this repo
- Live login: user 'aether' / password 'aether' • Secure Boot: OFF for v1.0 (custom kernel; signed-shim lands in v1.1)

$ARTLINE$JOINS

SHA256 ($NAME): $SHA")
curl -fsS -X PATCH -H "$AUTH" -H "Content-Type: application/json" \
  -d "$(python3 -c 'import json,sys; print(json.dumps({"body": sys.stdin.read()}))' <<<"$BODY")" \
  "$API/repos/$REPO/releases/$REL_ID" >/dev/null
echo "released."
