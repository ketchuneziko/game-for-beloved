#!/usr/bin/env python3
"""Плейсхолдер-песня для Главы 5 (заменяется твоим треком).

Генерирует assets/music/song.wav: мягкое «пианино» Am–F–C–G, 84 BPM,
10 строк мелодии по 2 такта. Тайминги строк совпадают с
data/custom/song.json. Запуск:  python3 tools/make_placeholder_song.py
"""
import os
import wave

import numpy as np

SR = 22050
BPM = 84.0
BEAT = 60.0 / BPM
BAR = 4 * BEAT
TOTAL_BARS = 28
DUR = TOTAL_BARS * BAR + 2.0

A3, C4, E4, F3, G3, B3, D4, F4, A4, C5, G4 = (
    220.0, 261.63, 329.63, 174.61, 196.0, 246.94, 293.66, 349.23, 440.0, 523.25, 392.0)
CHORDS = {
    "Am": [A3, C4, E4, A4],
    "F": [F3, A3, C4, F4],
    "C": [C4, E4, G4, C5],
    "G": [G3, B3, D4, G4],
}
ORDER = ["Am", "F", "C", "G"]


def note(buf, freq, t0, dur, amp=0.2, decay=3.0):
    n = int(SR * (dur + 0.4))
    t = np.arange(n) / SR
    env = np.exp(-decay * t) * np.minimum(1.0, t / 0.008)
    body = (np.sin(2 * np.pi * freq * t)
            + 0.35 * np.sin(4 * np.pi * freq * t + 0.3)
            + 0.12 * np.sin(6 * np.pi * freq * t))
    i0 = int(SR * t0)
    i1 = min(i0 + n, len(buf))
    if i0 >= len(buf):
        return
    buf[i0:i1] += (amp * env * body)[:i1 - i0]


def main() -> None:
    buf = np.zeros(int(SR * DUR))

    # Аккомпанемент: бас + арпеджио восьмыми.
    pattern = [0, 1, 2, 3, 2, 1, 2, 3]
    for bar in range(TOTAL_BARS):
        ch = CHORDS[ORDER[bar % 4]]
        t0 = bar * BAR
        note(buf, ch[0] / 2, t0, BAR * 0.9, amp=0.15, decay=1.2)
        for k, idx in enumerate(pattern):
            note(buf, ch[idx], t0 + k * BEAT / 2, 0.5, amp=0.09, decay=4.5)

    # Мелодия: строка = 2 такта (8 долей), ноты (офсет_долей, полутона от A4, доля).
    melody = [
        [(0, 0, 3), (4, 3, 2), (6, 5, 2)],
        [(8, 7, 3), (12, 5, 2), (14, 3, 2)],
        [(16, 5, 3), (20, 3, 2), (22, 0, 2)],
        [(24, -2, 3), (28, 0, 2), (30, 2, 2)],
        [(32, 3, 3), (36, 5, 2), (38, 7, 2)],
        [(40, 5, 3), (44, 3, 2), (46, 0, 2)],
        [(48, 0, 3), (52, -2, 2), (54, 0, 2)],
        [(56, -4, 3), (60, -2, 2), (62, 0, 2)],
        [(64, 0, 5), (70, 2, 2)],
        [(72, 5, 5), (78, 0, 2)],
    ]

    def semi(n: float) -> float:
        return A4 * (2 ** (n / 12.0))

    for line in melody:
        for beats, s, durb in line:
            t0 = 4 * BAR + beats * BEAT
            note(buf, semi(s), t0, durb * BEAT * 0.95, amp=0.2, decay=2.2)

    # Мягкий вход/выход и защита от клиппинга.
    ramp = int(SR * 1.5)
    buf[:ramp] *= np.linspace(0.0, 1.0, ramp)
    tail = int(SR * 3.0)
    buf[-tail:] *= np.linspace(1.0, 0.0, tail)
    peak = np.abs(buf).max()
    if peak > 0.9:
        buf *= 0.9 / peak

    pcm = (buf * 32767).astype(np.int16)
    out = os.path.join(os.path.dirname(__file__), "..", "assets", "music", "song.wav")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with wave.open(out, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("OK", os.path.abspath(out), round(DUR, 1), "sec,", os.path.getsize(out) // 1024, "KB")


if __name__ == "__main__":
    main()
