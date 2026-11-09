#!/usr/bin/env python3
"""Generate the Ravana startup sound: a short signature in Sri Lankan colours.

Original and synthesized (no samples, no recordings):
  0.00 s  Geta Bera  - deep tuned drum stroke (pitch falls as the skin settles) + soft slap
  0.00 s  Thalampata - small bright cymbal shimmer (inharmonic metal partials)
  0.18 s  Ravanahatha - bowed string phrase gliding Sa -> komal Ri -> Ga -> Pa
                        (Mayamalavagowla colour), with slides (meend) and vibrato
  0.20 s  drone       - soft Sa + Pa underneath, like a tanpura bed
  1.95 s  Udekki      - light hand-drum tap that closes the phrase
Clean stereo reverb, gentle level. 48 kHz stereo 16-bit WAV, ~3.3 s.
"""
import math, random, struct, wave
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "system_files/usr/share/sounds/ravana/startup.wav"
SR, DUR = 48000, 3.3
N = int(SR * DUR)
random.seed(7)
L = [0.0] * N
R = [0.0] * N

def add(n, v, pan):
    if 0 <= n < N:
        L[n] += v * (1 - pan)
        R[n] += v * pan

SA = 293.66                      # D4 as Sa
def note(semis): return SA * 2 ** (semis / 12)

# --- Geta Bera: low drum, pitch drops from ~95 to ~68 Hz, plus a short skin slap ---
def drum(start, f0, f1, amp, decay, pan, slap=0.25):
    s0 = int(start * SR)
    phase = 0.0
    for i in range(int(SR * 1.4)):
        t = i / SR
        f = f1 + (f0 - f1) * math.exp(-t * 18)
        phase += 2 * math.pi * f / SR
        e = math.exp(-t * decay) * (1 - math.exp(-t * 900))
        v = amp * e * (math.sin(phase) + 0.18 * math.sin(2.02 * phase) * math.exp(-t * 9))
        if t < 0.035:
            v += slap * amp * (random.random() * 2 - 1) * math.exp(-t * 120)
        add(s0 + i, v, pan)

# --- Thalampata: small cymbals, inharmonic metallic partials, quick shimmer ---
def cymbal(start, amp, pan):
    s0 = int(start * SR)
    partials = [(2350, 1.0), (3170, 0.7), (4410, 0.5), (5630, 0.35), (7020, 0.22)]
    for i in range(int(SR * 1.3)):
        t = i / SR
        e = math.exp(-t * 3.2) * (1 - math.exp(-t * 2000))
        v = sum(a * math.sin(2 * math.pi * f * t + a) for f, a in partials) / 2.8
        v += 0.12 * (random.random() * 2 - 1) * math.exp(-t * 40)
        add(s0 + i, amp * e * v, pan)

# --- Ravanahatha: bowed string, gliding between notes with vibrato ---
def bowed(start, path, amp, pan):
    """path: list of (time_from_start, semitone) targets; glides between them."""
    s0 = int(start * SR)
    end = path[-1][0] + 1.25
    phase = 0.0
    harm = [(1, 1.0), (2, 0.55), (3, 0.38), (4, 0.22), (5, 0.16), (6, 0.09), (7, 0.06)]
    for i in range(int(SR * end)):
        t = i / SR
        # current pitch: glide (meend) toward each target over 70 ms
        semis = path[0][1]
        for (tt, s), (tn, sn) in zip(path, path[1:]):
            if t >= tn:
                semis = sn
            elif t >= tt:
                k = min(1.0, (t - (tn - 0.07)) / 0.07) if t > tn - 0.07 else 0.0
                semis = s + (sn - s) * (k * k * (3 - 2 * k))
                break
        vib = 0.18 * min(1.0, max(0.0, (t - 0.35) / 0.6)) * math.sin(2 * math.pi * 5.6 * t)
        f = note(semis + vib)
        phase += 2 * math.pi * f / SR
        attack = 1 - math.exp(-t * 14)
        release = 1.0 if t < end - 1.1 else math.exp(-(t - (end - 1.1)) * 3.2)
        bow = 1 + 0.06 * math.sin(2 * math.pi * 3.1 * t)          # slight bow pressure sway
        v = sum(a * math.sin(h * phase) for h, a in harm) / 2.6
        v += 0.035 * (random.random() * 2 - 1)                     # bow hair noise
        add(s0 + i, amp * attack * release * bow * v, pan)

# --- Drone: Sa + Pa, soft and wide ---
def drone(start, amp):
    s0 = int(start * SR)
    for i in range(int(SR * (DUR - start))):
        t = i / SR
        e = (1 - math.exp(-t * 3)) * math.exp(-t * 0.9)
        v = (math.sin(2 * math.pi * SA / 2 * t) + 0.6 * math.sin(2 * math.pi * note(7) / 2 * t)
             + 0.25 * math.sin(2 * math.pi * SA * t)) / 1.9
        add(s0 + i, amp * e * v * 0.5, 0.35)
        add(s0 + i, amp * e * v * 0.5, 0.65)

drum(0.00, 95, 68, 0.95, 4.2, 0.45)                 # Geta Bera
cymbal(0.00, 0.20, 0.70)                            # Thalampata
drone(0.20, 0.22)
bowed(0.18, [(0.00, -1), (0.10, 0), (0.42, 1), (0.62, 4), (0.95, 7)], 0.42, 0.52)  # Sa r G P
drum(1.95, 210, 175, 0.35, 9.0, 0.60, slap=0.45)    # Udekki tap
cymbal(1.95, 0.08, 0.30)

# --- clean stereo reverb (decaying cross-fed taps) ---
for delay_ms, gain in ((29, 0.30), (43, 0.25), (61, 0.20), (89, 0.16), (127, 0.12), (181, 0.08), (251, 0.05)):
    d = int(SR * delay_ms / 1000)
    for n in range(N - 1, d - 1, -1):
        L[n] += gain * R[n - d]
        R[n] += gain * L[n - d]

peak = max(max(abs(x) for x in L), max(abs(x) for x in R))
scale = 0.62 / peak
fade = int(SR * 0.35)
OUT.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(OUT), "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    out = bytearray()
    for n in range(N):
        g = scale * (1.0 if n < N - fade else (N - n) / fade)
        out += struct.pack("<hh", int(max(-1, min(1, L[n] * g)) * 32767), int(max(-1, min(1, R[n] * g)) * 32767))
    w.writeframes(bytes(out))
print("wrote", OUT.relative_to(OUT.parents[5]), f"{OUT.stat().st_size // 1024} KB, {DUR} s")
