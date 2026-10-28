#!/bin/bash
# ci/release.sh — attach the ISO to the GitHub Release for this tag (skips if asset exists).
set -euo pipefail
API="https://api.github.com"
AUTH="Authorization: token $GH_TOKEN"
ISO=$(ls dist/*.iso | head -1)
NAME=$(basename "$ISO")
SHA=$(sha256sum "$ISO" | cut -d' ' -f1)

REL=$(curl -fsS -H "$AUTH" "$API/repos/$REPO/releases/tags/$TAG" 2>/dev/null || true)
if [ -z "$REL" ]; then
  REL=$(curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"tag_name\":\"$TAG\",\"name\":\"AetherOS $TAG (Nebula)\",\"body\":\"AetherOS 1.0 — first bootable release.\\n\\n- AetherOS kernel compiled from kernel.org source (gaming-tuned: 1000Hz, full preemption, binderfs, zram)\\n- Plasma 6 Wayland desktop, macOS-style layout\\n- Wine + Bottles (Windows apps), Waydroid (Android apps), Steam/gamemode/MangoHud\\n- Debian 13 (trixie) base floor\\n\\nSHA256: $SHA\",\"draft\":false,\"prerelease\":false}" \
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
