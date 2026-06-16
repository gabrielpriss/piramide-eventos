#!/usr/bin/env python3
"""Gera versões WebP redimensionadas das fotos usadas no site."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "assets" / "FOTOS PRIME"
OUT_DIR = ROOT / "assets" / "img"

USED = [
    "AR2A0823.jpg", "IMG_1747.jpg", "IMG_9853.JPG", "BL7A8780.jpg",
    "AR2A0826.jpg", "IMG_9851.JPG", "BL7A8783.jpg", "BL7A8787.jpg",
    "BL7A8789.jpg", "AR2A0821.jpg", "AR2A0830.jpg", "IMG_9855.JPG", "BL7A8782.jpg",
]

SIZES = {"xl": 1600, "lg": 1200, "md": 800}
LOGO_SIZES = {"lg": 840, "sm": 320}
QUALITY = 82


def resize_to_width(img: Image.Image, target_w: int) -> Image.Image:
    w, h = img.size
    if w <= target_w:
        return img.copy()
    ratio = target_w / w
    return img.resize((target_w, max(1, int(h * ratio))), Image.Resampling.LANCZOS)


def save_webp(img: Image.Image, path: Path) -> None:
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGB")
    img.save(path, "WEBP", quality=QUALITY, method=6)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for name in USED:
        src = SRC_DIR / name
        if not src.exists():
            raise FileNotFoundError(src)
        stem = Path(name).stem
        with Image.open(src) as im:
            for label, width in SIZES.items():
                save_webp(resize_to_width(im, width), OUT_DIR / f"{stem}-{label}.webp")

    logo_src = ROOT / "assets" / "logoTransparente.png"
    if logo_src.exists():
        with Image.open(logo_src) as im:
            if im.mode != "RGBA":
                im = im.convert("RGBA")
            for label, width in LOGO_SIZES.items():
                resized = resize_to_width(im, width)
                resized.save(OUT_DIR / f"logo-{label}.webp", "WEBP", quality=90, method=6)

    print(f"OK: arquivos em {OUT_DIR}")


if __name__ == "__main__":
    main()
