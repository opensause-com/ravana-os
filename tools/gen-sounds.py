#!/usr/bin/env python3
# Copyright (c) 2026 Ravana OS. All rights reserved.
"""Ravana system sounds: small cousins of the Ghanta startup bell, so the whole OS
sounds like one family. Short, soft and mixed quietly (about -14 dBFS peaks).

  notification  two light bell strikes, a fourth apart ("ting-ting")
  volume        a tiny bronze tap for volume feedback
  plug          a rising pair when power is connected
  alert         a lower, darker double strike for warnings and errors
  complete      a single bright strike (copies done, downloads finished)
  trash         a soft papery swish with a low tap

Writes WAVs into system_files/usr/share/sounds/ravana/stereo/ under the
freedesktop sound-naming names, plus an index.theme, so apps' event sounds use them too.
"""
import math, random, struct, wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "system_files/usr/share/sounds/ravana"
SR = 48000
TWO_PI = 2 * math.pi
random.seed(7)

# bronze partials (ratio, level, decay per second) - same family as the Ghanta
BRONZE = [(1.00, 1.00, 6.0), (2.00, 0.45, 9.0), (2.76, 0.30, 12.0), (3.97, 0.16, 16.0), (5.40, 0.08, 22.0)]

def strike(buf, start, f0, amp, decay_scale=1.0, pan=0.5):
    s0 = int(start * SR)
    n = len(buf[0])
    for i in range(max(0, n - s0)):
        t = i / SR
        att = min(1.0, t / 0.004)                       # soft clapper attack
        v = 0.0
        for r, lvl, d in BRONZE:
            v += lvl * math.exp(-t * d * decay_scale) * math.sin(TWO_PI * f0 * r * t + r)
        v *= amp * att
        buf[0][s0 + i] += v * (1.1 - pan)
        buf[1][s0 + i] += v * (0.1 + pan)

def swish(buf, start, dur, amp):
    s0 = int(start * SR); prev = 0.0
    for i in range(int(dur * SR)):
        t = i / SR
        env = math.sin(math.pi * t / dur) ** 2
        prev = prev * 0.92 + (random.random() * 2 - 1) * 0.08   # soft, papery noise
        v = prev * env * amp
        if s0 + i < len(buf[0]):
            buf[0][s0 + i] += v; buf[1][s0 + i] += v

def write(name, buf, peak_db=-14.0):
    peak = max(1e-9, max(max(abs(x) for x in ch) for ch in buf))
    g = (10 ** (peak_db / 20)) / peak
    n = len(buf[0])
    fade = int(0.02 * SR)
    out = bytearray()
    for i in range(n):
        f = min(1.0, (n - i) / fade)
        for ch in buf:
            out += struct.pack("<h", int(max(-1, min(1, ch[i] * g * f)) * 32767))
    p = ROOT / "stereo" / f"{name}.wav"
    p.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(p), "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(bytes(out))
    print("wrote", p.relative_to(ROOT.parent.parent.parent.parent), f"{n / SR:.2f}s")

def new(dur): n = int(dur * SR); return [[0.0] * n, [0.0] * n]

b = new(0.9);  strike(b, 0.0, 1318.5, 1.0, 1.0, 0.45); strike(b, 0.11, 1760.0, 0.8, 1.0, 0.55); write("message-new-instant", b)
b = new(0.18); strike(b, 0.0, 1975.5, 1.0, 4.0); write("audio-volume-change", b, -18.0)
b = new(0.8);  strike(b, 0.0, 987.8, 0.8, 1.2, 0.4); strike(b, 0.09, 1318.5, 1.0, 1.1, 0.6); write("power-plug", b)
b = new(0.9);  strike(b, 0.0, 659.3, 1.0, 1.1, 0.45); strike(b, 0.14, 523.3, 0.9, 1.1, 0.55); write("dialog-warning", b)
b = new(0.7);  strike(b, 0.0, 1567.9, 1.0, 1.3); write("complete", b)
b = new(0.5);  swish(b, 0.0, 0.32, 0.9); strike(b, 0.24, 392.0, 0.35, 3.0); write("trash-empty", b, -16.0)

(ROOT / "index.theme").write_text("""[Sound Theme]
Name=Ravana
Comment=Ravana OS system sounds (bronze bell family)
Inherits=freedesktop
Directories=stereo

[stereo]
OutputProfile=stereo
""")
print("wrote index.theme")
