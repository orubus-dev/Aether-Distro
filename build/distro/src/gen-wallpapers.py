#!/usr/bin/env python3
# AetherOS wallpaper generator — aurora gradients, no external assets (license-clean).
import struct, zlib, os
try:
    import numpy as np
except ImportError:
    np = None
W, H = 2560, 1440
OUT = os.path.dirname(os.path.abspath(__file__)) + "/wallpapers"

def write_png(path, rgb):
    raw = b"".join(b"\x00" + rgb[y].tobytes() for y in range(H))
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    open(path, "wb").write(png)

def grad(name, stops):
    # vertical multi-stop gradient + diagonal aurora glow + subtle vignette
    rows = np.zeros((H, W, 3), dtype=np.uint8)
    ys = np.linspace(0, 1, H)[:, None]
    xs = np.linspace(0, 1, W)[None, :]
    col = np.zeros((H, 3))
    n = len(stops) - 1
    t = ys * n
    idx = np.clip(t.astype(int), 0, n - 1)
    frac = t - idx
    for c in range(3):
        a = np.array([s[1][c] for s in stops])
        col[:, c] = (a[idx[:,0]] * (1 - frac[:,0]) + a[idx[:,0]+1] * frac[:,0])
    img = np.repeat(col[:, None, :], W, axis=1)
    # aurora glow (radial, upper-left violet + lower-right cyan)
    r1 = np.sqrt((xs-0.22)**2 + (ys*1.4-0.18)**2)
    r2 = np.sqrt((xs-0.85)**2 + (ys*1.2-0.88)**2)
    g1 = 34 * np.exp(-(r1**2)/0.06); g2 = 28 * np.exp(-(r2**2)/0.08)
    img[:,:,2] += (g1+g2)
    img[:,:,0] += g1 * 0.9   # violet into red
    img[:,:,1] += g2 * 0.5   # teal into green
    # dithered vignette
    rng = np.random.default_rng(7)
    vig = 1 - 0.22 * (np.sqrt((xs-0.5)**2 + (ys-0.5)**2) / 0.71)**2
    img = img * vig[:,:,None] + rng.normal(0, 1.1, img.shape)
    rows = np.clip(img, 0, 255).astype(np.uint8)
    write_png(f"{OUT}/{name}.png", rows)
    print("wrote", name)

os.makedirs(OUT, exist_ok=True)
grad("aether-night", [(0.00,(9,12,32)), (0.45,(38,28,84)), (0.75,(96,52,140)), (1.00,(20,26,58))])
grad("aether-dawn",  [(0.00,(240,244,252)), (0.50,(198,206,240)), (0.80,(150,168,222)), (1.00,(210,218,244))])
