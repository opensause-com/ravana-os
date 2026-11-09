#!/usr/bin/env python3
"""Generate the Ravana startup chime (original, synthesized; no samples).

A warm, airy chord (D major add9 spread over three octaves): each note is a soft
sine with a little bell-like 2nd/3rd harmonic, notes enter a few ms apart like a
gentle strum, a slow swell then a long exponential fade, a touch of stereo width
and a short reverb tail. 48 kHz stereo 16-bit WAV, ~2.6 s.
"""
import math, struct, wave
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "system_files/usr/share/sounds/ravana/startup.wav"
SR, DUR = 48000, 2.6
N = int(SR * DUR)

# D2, A2, D3, F#3, A3, E4, A4 (Hz)
NOTES = [(73.42, 0.55, 0.000), (110.0, 0.45, 0.012), (146.83, 0.50, 0.024), (185.0, 0.40, 0.036),
         (220.0, 0.38, 0.048), (329.63, 0.30, 0.064), (440.0, 0.22, 0.080)]

def env(t, start):
    t -= start
    if t < 0: return 0.0
    attack = 0.09
    a = (t / attack) ** 2 if t < attack else 1.0
    return a * math.exp(-max(0.0, t - attack) * 1.55)

left = [0.0] * N
right = [0.0] * N
for i, (f, amp, start) in enumerate(NOTES):
    pan = 0.5 + (i - len(NOTES) / 2) * 0.06          # spread notes across the stereo field
    detune = 1.0 + (0.0012 if i % 2 else -0.0012)    # slight chorus
    for n in range(N):
        t = n / SR
        e = env(t, start)
        if e < 1e-5: continue
        w = 2 * math.pi * f * t
        s = (math.sin(w) + 0.22 * math.sin(2 * w * detune) * math.exp(-t * 3.0)
             + 0.08 * math.sin(3 * w) * math.exp(-t * 5.0))
        v = amp * e * s
        left[n] += v * (1 - pan)
        right[n] += v * pan

# short, soft reverb: a few decaying taps, cross-fed between channels
for delay_ms, gain in ((37, 0.28), (53, 0.22), (79, 0.17), (113, 0.12), (157, 0.08)):
    d = int(SR * delay_ms / 1000)
    for n in range(N - 1, d - 1, -1):
        left[n] += gain * right[n - d]
        right[n] += gain * left[n - d]

peak = max(max(abs(x) for x in left), max(abs(x) for x in right))
scale = 0.6 / peak                                   # leave headroom: about -4.4 dBFS
fade = int(SR * 0.25)
OUT.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(OUT), "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    frames = bytearray()
    for n in range(N):
        g = scale * (1.0 if n < N - fade else (N - n) / fade)
        frames += struct.pack("<hh", int(left[n] * g * 32767), int(right[n] * g * 32767))
    w.writeframes(bytes(frames))
print("wrote", OUT.relative_to(OUT.parents[5]), f"{OUT.stat().st_size // 1024} KB")
