#!/usr/bin/env python3
"""Capture the whole KWin workspace through org.kde.KWin.ScreenShot2 and save a PNG.
Usage: capture.py out.png   (needs KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1 in KWin's env)"""
import os, struct, sys, zlib
import dbus

out = sys.argv[1]
bus = dbus.SessionBus()
kwin = bus.get_object("org.kde.KWin", "/org/kde/KWin/ScreenShot2")
iface = dbus.Interface(kwin, "org.kde.KWin.ScreenShot2")
r, w = os.pipe()
meta = iface.CaptureWorkspace({"native-resolution": dbus.Boolean(True)}, dbus.types.UnixFd(w), timeout=30)
os.close(w)
data = b""
with os.fdopen(r, "rb") as f:
    while True:
        chunk = f.read(1 << 20)
        if not chunk:
            break
        data += chunk
width, height, stride = int(meta["width"]), int(meta["height"]), int(meta["stride"])
# KWin hands back RGBA bytes
rows = []
for y in range(height):
    row = data[y * stride: y * stride + width * 4]
    rgb = bytearray(width * 3)
    rgb[0::3] = row[0::4]
    rgb[1::3] = row[1::4]
    rgb[2::3] = row[2::4]
    rows.append(b"\x00" + bytes(rgb))
raw = b"".join(rows)

def chunk(tag, body):
    return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)

png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))
open(out, "wb").write(png)
print(f"saved {out} {width}x{height}")
