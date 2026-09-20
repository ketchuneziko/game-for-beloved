#!/usr/bin/env python3
"""Пикселизация фонов до 320x180 (классика 16:9) с ограниченной палитрой.
Файлы PNG остаются маленькими, движок растягивает их методом «ближайшего
соседа» (texture_filter = NEAREST) — пиксели чёткие. Запуск:
python3 tools/pixelate_backgrounds.py [источник_jpg] (по умолчанию конвертация
существующих .jpg в assets/backgrounds).
"""
import os
import sys

from PIL import Image

DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "backgrounds")
W, H = 320, 180
COLORS = 64


def pixelate(img: Image.Image) -> Image.Image:
    small = img.convert("RGB").resize((W, H), Image.LANCZOS)
    quant = small.convert("P", palette=Image.ADAPTIVE, colors=COLORS)
    return quant.convert("RGB")


def main() -> None:
    src_dir = sys.argv[1] if len(sys.argv) > 1 else DIR
    for f in sorted(os.listdir(src_dir)):
        if not f.endswith(".jpg"):
            continue
        p = os.path.join(src_dir, f)
        out = os.path.join(DIR, f[:-4] + ".png")
        pixelate(Image.open(p)).save(out, "PNG", optimize=True)
        print(f, "->", os.path.basename(out), os.path.getsize(out) // 1024, "KB")
        os.remove(p)


if __name__ == "__main__":
    main()
