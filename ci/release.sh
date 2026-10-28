#!/bin/bash
# ci/release.sh — attach the ISO to the GitHub Release for this tag (skips if asset exists).
set -euo pipefail
API="https://api.github.com"
AUTH="Authorization: token $GH_TOKEN"
ISO=$(ls dist/*.iso | head -1)
NAME=$(basename "$ISO")
SHA=$(sha256sum "$ISO" | cut -d' ' -f1)
SIZE=$(stat -c%s "$ISO")

REL=$(curl -fsS -H "$AUTH" "$API/repos/$REPO/releases/tags/$TAG" 2>/dev/null || true)
BODY=$(printf '%s' "AetherOS $TAG (Nebula) — bootable release.\n\n## What's inside\n- AetherOS kernel compiled from kernel.org source (gaming-tuned: 1000Hz, full preemption, binderfs, zram)\n- Plasma 6 Wayland desktop, macOS-style layout\n- Wine + Bottles (Windows apps), Waydroid (Android apps), Steam/gamemode/MangoHud\n- Debian 13 (trixie) base floor; Calamares installer; UEFI + Legacy boot\n\n## No-flash quick start (download → run, no burning)\n- **Zero flashing, forever:** install Ventoy on a stick ONCE (2 min, https://www.ventoy.net) — after that every ISO is just a file you copy onto the stick and boot\n- **From your phone:** download the ISO here → copy to the Ventoy stick via USB-OTG → boot any PC\n- **No USB at all:** open the ISO in VirtualBox/VMware and it boots\n- Full guide: docs/NO-FLASH-START.md in this repo\n- Live login: user 'aether' / password 'aether' • Secure Boot: OFF for v1.0 (custom kernel, signed-shim lands in v1.1)\n\nSHA256 ($NAME): $SHA")
if [ -z "$REL" ]; then
  REL=$(curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"tag_name\":\"$TAG\",\"name\":\"AetherOS $TAG (Nebula)\",\"body\":$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' <<<"$BODY"),\"draft\":false,\"prerelease\":false}" \
    "$API/repos/$REPO/releases")
fi
UPLOAD_URL=$(echo "$REL" | python3 -c "import json,sys; print(json.load(sys.stdin)['upload_url'].split('{')[0])")
if echo "$REL" | grep -q "\"name\": \"$NAME\""; then
  echo "asset already present — skipping upload"; exit 0
fi
echo "uploading $NAME ($(stat -c%s "$ISO") bytes)..."
curl -fS -X POST -H "$AUTH" -H "Content-Type: application/octet-stream" \
  --data-binary @"$ISO" "$UPLOAD_URL?name=$NAME" -o /dev/null
curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/octet-stream" \
  --data-binary @dist/SHA256SUMS "$UPLOAD_URL?name=SHA256SUMS.txt" -o /dev/null || true
echo "released."
