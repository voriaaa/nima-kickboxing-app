"""Synthesizes the timer sounds (no external audio needed).
Run: python3 tool/make_sounds.py   (needs numpy)
  warn.wav       two sharp wooden clacks  -> 10 seconds before the end
  bell_start.wav one boxing bell strike   -> round starts
  bell_end.wav   three bell strikes       -> round ends / session finished"""
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")


def write(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.92
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def bell_strike(length=2.2, base=830.0):
    t = np.arange(int(SR * length)) / SR
    partials = [(1.0, 1.00, 2.6), (1.5, 0.45, 2.0), (2.0, 0.55, 1.8), (2.76, 0.40, 1.3),
                (3.4, 0.28, 1.0), (4.1, 0.18, 0.8), (5.4, 0.12, 0.6)]
    x = np.zeros_like(t)
    for ratio, amp, decay in partials:
        x += amp * np.sin(2 * np.pi * base * ratio * t) * np.exp(-t * decay * 1.6)
    # hammer transient
    x += 0.5 * np.random.default_rng(1).standard_normal(len(t)) * np.exp(-t * 220)
    x *= np.minimum(1, t / 0.002)
    return x


def place(total, strikes, sound):
    out = np.zeros(int(SR * total))
    for s in strikes:
        i = int(SR * s)
        n = min(len(sound), len(out) - i)
        out[i:i + n] += sound[:n]
    return out


def clack():
    t = np.arange(int(SR * 0.14)) / SR
    rng = np.random.default_rng(7)
    noise = rng.standard_normal(len(t)) * np.exp(-t * 140)
    body = np.sin(2 * np.pi * 1650 * t) * np.exp(-t * 55) + 0.6 * np.sin(2 * np.pi * 2480 * t) * np.exp(-t * 70)
    return noise * 0.7 + body


write("warn.wav", place(0.55, [0.0, 0.2], clack()))
write("bell_start.wav", place(2.3, [0.0], bell_strike()))
write("bell_end.wav", place(3.1, [0.0, 0.5, 1.0], bell_strike(2.1)))
print("sounds written")
