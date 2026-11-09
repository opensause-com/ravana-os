#!/usr/bin/env python3
"""Ravana startup sound: the Ghanta - a single kovil temple-bell strike.

A bronze ghanta struck once: bell partials (hum, prime, tierce, quint, nominal and
upper partials) that ring and beat slowly, with a soft clapper attack, in a stone
temple-hall echo. Optional Thavil 'dhom' and Jalra underneath. Original, synthesized.

Usage: gen-chime.py [out.wav] [--with-drums]   (default: the bell alone, Ravana's sound)
"""
import math, random, struct, sys, wave
from pathlib import Path

args = [a for a in sys.argv[1:] if not a.startswith("--")]
BELL_ONLY = "--with-drums" not in sys.argv
OUT = Path(args[0]) if args else \
    Path(__file__).resolve().parent.parent / "system_files/usr/share/sounds/ravana/startup.wav"
SR, DUR = 48000, 4.2
N = int(SR * DUR)
random.seed(5)
L = [0.0] * N
R = [0.0] * N
TWO_PI = 2 * math.pi

def add(n, v, pan):
    if 0 <= n < N:
        L[n] += v * (1 - pan)
        R[n] += v * pan

def noise(): return random.random() * 2 - 1

# Ghanta: bronze temple bell. (ratio, level, decay/s, beat Hz) - each partial is a slightly
# split pair, which gives the slow 'wah-wah' shimmer of a real bronze bell.
GHANTA = [(0.50, 0.55, 0.55, 0.9), (1.00, 1.00, 0.80, 1.3), (1.19, 0.62, 1.05, 1.7),
          (1.50, 0.40, 1.30, 2.1), (2.00, 0.55, 1.45, 1.1), (2.52, 0.30, 2.0, 2.6),
          (3.01, 0.22, 2.6, 3.0), (4.16, 0.12, 3.6, 3.4), (5.43, 0.07, 4.8, 4.0)]

def ghanta(start, f0, amp, pan):
    s0 = int(start * SR)
    for i in range(int(SR * (DUR - start))):
        t = i / SR
        v = 0.0
        for ratio, a, dec, beat in GHANTA:
            f = f0 * ratio
            v += a * math.exp(-t * dec) * (math.sin(TWO_PI * f * t)
                                            + 0.6 * math.sin(TWO_PI * (f + beat) * t + 0.7))
        if t < 0.006:
            v += 1.1 * noise() * (1 - t / 0.006)            # clapper strike
        att = 1 - math.exp(-t * 2500)
        add(s0 + i, amp * att * v / 5.0, pan)

def dhom(start, amp, pan):
    s0 = int(start * SR); phase = 0.0
    for i in range(int(SR * 1.6)):
        t = i / SR
        f = 58 + 46 * math.exp(-t * 20)
        phase += TWO_PI * f / SR
        e = math.exp(-t * 4.2) * (1 - math.exp(-t * 1200))
        v = math.sin(phase) + 0.22 * math.sin(2.1 * phase) * math.exp(-t * 9)
        if t < 0.02: v += 0.35 * noise() * math.exp(-t * 180)
        add(s0 + i, amp * e * v, pan)

def jalra(start, amp, pan):
    s0 = int(start * SR)
    parts = [(3120, 1.0), (4380, 0.8), (5710, 0.6), (7290, 0.4), (8830, 0.25)]
    for i in range(int(SR * 1.2)):
        t = i / SR
        e = math.exp(-t * 4.5) * (1 - math.exp(-t * 3000))
        v = sum(a * math.sin(TWO_PI * f * t + a) for f, a in parts) / 3 + 0.18 * noise() * math.exp(-t * 60)
        add(s0 + i, amp * e * v, pan)

ghanta(0.02, 560, 0.85, 0.52)                 # main strike (deep, temple-sized bell)
if not BELL_ONLY:
    dhom(0.00, 0.55, 0.48)
    jalra(0.00, 0.10, 0.30)

def hall(x, combs, allpasses, fb=0.80, damp=0.32, wet=0.32):
    out = [0.0] * len(x)
    for d in combs:
        buf = [0.0] * d; idx = 0; lp = 0.0
        for n in range(len(x)):
            y = buf[idx]; lp = y * (1 - damp) + lp * damp
            buf[idx] = x[n] + lp * fb; idx = (idx + 1) % d
            out[n] += y / len(combs)
    for d in allpasses:
        buf = [0.0] * d; idx = 0
        for n in range(len(out)):
            b = buf[idx]; y = -out[n] + b
            buf[idx] = out[n] + b * 0.5; idx = (idx + 1) % d
            out[n] = y
    return [a * (1 - wet) + b * wet * 1.8 for a, b in zip(x, out)]

L = hall(L, (1557, 1617, 1491, 1422), (225, 556))
R = hall(R, (1580, 1640, 1514, 1445), (248, 579))

peak = max(max(abs(v) for v in L), max(abs(v) for v in R))
scale = 0.70 / peak
fade = int(SR * 0.6)
OUT.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(OUT), "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    buf = bytearray()
    for n in range(N):
        g = scale * (1.0 if n < N - fade else (N - n) / fade)
        buf += struct.pack("<hh", int(max(-1, min(1, L[n] * g)) * 32767), int(max(-1, min(1, R[n] * g)) * 32767))
    w.writeframes(bytes(buf))
print("wrote", OUT, f"{OUT.stat().st_size // 1024} KB, {DUR} s")
