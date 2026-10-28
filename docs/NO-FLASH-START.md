# AetherOS — No-Flash Quick Start

You asked for it: **download the ISO and run it — no burning, no flashing, no Etcher, no Rufus.**
Here are the 3 ways that actually work, ranked.

---

## First: what "flashing" actually is (30 seconds)

An ISO is a bit-for-bit image of a bootable disc. A plain USB stick with `aetheros.iso` copied onto it will **not** boot — the stick needs those bytes laid out in a bootable layout. That layout step is what Etcher/Rufus call "flashing".

You only have to do that step **once in your life** (Option 1, 2 minutes), or never at all (Option 3).

---

## Option 1 — Ventoy: flash ONCE, never again (recommended)

Ventoy turns any USB stick into a "just copy the ISO file" stick. After the one-time install, **an ISO file you drag onto the stick is instantly bootable**. No tools, no flashing, ever again.

**One-time setup (needs a PC for ~2 minutes — any PC, a friend's laptop, a school PC, whatever):**

1. Download Ventoy from <https://www.ventoy.net> — `ventoy-x.x.xx-windows.zip` (Windows) or the Linux `.tar.gz`
2. Unzip → run `Ventoy2Disk.exe` (Windows) or `./VentoyGUI.x86_64` (Linux)
3. Select your USB stick → **Install** (⚠️ this wipes the stick *once*)
4. Done. The stick is now a normal USB drive again — but every ISO you copy onto it becomes bootable.

**Every time after that (this is the part you'll actually live with):**

```
Download aetheros ISO  →  drag the .iso file onto the USB stick  →  boot the PC from USB
```

That's it. No Etcher. No Rufus. No "write image". Just a file copy.

---

## Option 2 — The phone workflow (after the one-time Ventoy setup)

You can genuinely do the whole thing from an Android phone:

1. **Download** the ISO from the [Releases page](https://github.com/orubus-dev/Aether-Distro/releases) on your phone (~2.9 GB, keep ~6 GB free)
2. **Check it** (optional but easy): install *Termux* and run `sha256sum /sdcard/Download/<iso-file>`, or any "hash checker" app — compare with the `SHA256SUMS.txt` in the release
3. **Copy**: plug the Ventoy stick into the phone with a **USB-OTG adapter** → copy the ISO onto it with any file manager
4. **Use it**: plug the stick into any PC/laptop → power on → tap the boot-menu key → pick the USB → AetherOS starts

No PC software is ever needed for steps 1–3. The stick remembers Ventoy — you're just moving a file.

---

## Option 3 — Zero USB at all: run the ISO in a VM

If you just want to **use AetherOS right now** and have any PC available (Windows/macOS/Linux):

1. Install VirtualBox (free) — <https://www.virtualbox.org>
2. New VM → 4 GB RAM, 2 CPUs, 40 GB disk
3. When asked for a disk image, **pick the downloaded ISO** → Start
4. AetherOS boots into the live desktop. Nothing is written to any USB stick, anywhere.

QEMU/VMware work the same way. This is the literal "download it, run the ISO" path.

---

## Booting a real PC from the stick

| Step | What to do |
|---|---|
| 1 | Plug the Ventoy stick into the PC |
| 2 | Power on and tap the boot-menu key repeatedly: **F12** (Dell/Lenovo/Acer), **F9** (HP), **F8** (Asus), **Esc** (others) |
| 3 | Pick the USB entry (pick the **UEFI:** one if both appear) |
| 4 | Ventoy's menu appears → pick the AetherOS ISO → it boots |
| 5 | AetherOS live session autologins as user `aether` (password `aether`) |

- **UEFI and Legacy BIOS both work.**
- **Secure Boot: turn it OFF in the firmware for v1.0.** The AetherOS kernel is compiled from kernel.org source with a gaming-tuned config and is not Microsoft-signed; a signed-shim + MOK enrollment flow lands in v1.1. (Firmware settings → Security → Secure Boot → Disabled.)
- To install permanently to the disk, open **Install AetherOS** (Calamares) from the desktop.

---

## Verify the download (paranoid mode)

Every release ships a `SHA256SUMS.txt`. On any Linux/Mac: `sha256sum -c SHA256SUMS.txt`. On Android: Termux `sha256sum <file>`. On Windows: `certutil -hashfile <iso> SHA256`.
