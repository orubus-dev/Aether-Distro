# Aether Distro

A real laptop operating system built from the Linux kernel up — gaming-tuned, power-efficient on 8GB RAM, with a polished desktop and one home for Linux, Windows, and Android apps.

## What ships in v1.0
| Layer | Implementation |
|---|---|
| Kernel | **Compiled from kernel.org source** with the AetherOS config (02-kernel): 1000Hz + full preemption, binderfs (Android apps), built-in zram, full laptop GPU/WiFi set. No distro kernel. |
| Desktop | Plasma 6 Wayland, macOS-style layout (menu bar + floating dock + blur), WhiteSur themes, Inter type |
| Windows apps | Wine + winetricks baked; Bottles via one click in Aether Welcome |
| Android apps | Waydroid — works out of the box on the Aether kernel (binderfs built-in) |
| Gaming | gamemode + MangoHud + Steam launcher baked; schedutil + full-performance caps, no underclocking |
| Battery | zram memory layering (8GB-friendly), thermald, earlyoom, power-profiles-daemon |
| Linux apps | apt + Flatpak (flathub pre-configured) + Discover |
| Installer | Calamares with Aether branding — full-disk or manual, LUKS capable, EFI + Secure Boot |
| Floor | Debian 13 (trixie) base binaries — v1.1+ replaces these with our own package repo |

## Run it — no flashing required
Download the ISO from [Releases](https://github.com/orubus-dev/Aether-Distro/releases) and read **[docs/NO-FLASH-START.md](docs/NO-FLASH-START.md)**: Ventoy (flash a stick once, then every ISO is just a file you copy and boot), the full phone-only workflow (download + USB-OTG copy + boot), or zero-USB (open the ISO in VirtualBox).

## Build it
```bash
./build/kernel/build.sh      # kernel: kernel.org source -> linux-image-aether .deb
./build/distro/build.sh all  # distro: live-build -> bootable ISO (needs the kernel deb)
```
CI does exactly this on every tag — see .github/workflows/iso.yml. Every build log is public.

## Verify the core
```bash
make all   # 14 test suites: foundation, services, Aegis security, capabilities, hardware
```

## Docs
- docs/architecture.md — the 55-layer system design
- docs/bridge-v1.md — how v1.0 maps the layers to shipped components
- docs/roadmap.md — phases

