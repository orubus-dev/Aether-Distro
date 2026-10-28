# Bridge: Aether layers -> v1.0 shipped components

v1.0 ships the full desktop OS experience while the native Aether init matures. Mapping:

| Layer(s) | v1.0 component | Ownership |
|---|---|---|
| 02-kernel | linux-image-aether, compiled from kernel.org source, our config | ours, from source |
| 03-init | systemd (temporary PID 1) | borrowed, native init (03-init) already builds + tested |
| 04-31 (services/security) | Aether core + Aegis libraries, 14 test suites green in CI | ours, native |
| 19-21 (power/battery/thermal) | power-profiles-daemon + thermald + zram-generator + our sysctls/udev | ours (policy), upstream daemons |
| 38-40 (runtimes) | Wine (Windows), Waydroid (Android), native ELF (Linux) | ours (integration), upstream runtimes |
| 42-44 (graphics/video) | Mesa + KWin compositing, VAAPI/Vulkan | borrowed libs, ours (config) |
| 49-53 (desktop shell) | Plasma 6 + Aether layout/theme/welcome/apps | ours (experience) |
| 34-installer | Calamares + Aether branding | ours (branding/flow) |
| 32-update | apt/flatpak + Aether Welcome updater | ours (glue) |

Floor (borrowed, shrinking): glibc, Mesa, Qt, Wine binaries from Debian 13.
