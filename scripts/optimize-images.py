#!/usr/bin/env python3
"""Gera WebP redimensionadas — apenas imagens da versão dark (produção)."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "assets" / "FOTOS PRIME"
OUT_DIR = ROOT / "assets" / "img"

# Fotos usadas exclusivamente na versão dark
USED = [
    "AR2A0823.jpg",
    "IMG_1747.jpg",
    "IMG_9853.JPG",
    "BL7A8780.jpg",
    "AR2A0826.jpg",
    "IMG_9851.JPG",
    "BL7A8783.jpg",
    "BL7A8787.jpg",
]

# Tamanhos necessários por foto (build.sh copia apenas estes)
SIZES_BY_STEM = {
    "AR2A0823": ("xl", "lg", "md"),
    "IMG_1747": ("lg", "md"),
    "BL7A8780": ("lg", "md"),
    "BL7A8783": ("lg", "md"),
    "IMG_9853": ("lg",),
    "AR2A0826": ("lg",),
    "IMG_9851": ("lg",),
    "BL7A8787": ("lg",),
}

SIZE_WIDTH = {"xl": 1600, "lg": 1200, "md": 800}
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
        labels = SIZES_BY_STEM.get(stem, ("lg", "md"))
        with Image.open(src) as im:
            for label in labels:
                save_webp(
                    resize_to_width(im, SIZE_WIDTH[label]),
                    OUT_DIR / f"{stem}-{label}.webp",
                )

    logo_src = ROOT / "assets" / "logoTransparente.png"
    if logo_src.exists():
        with Image.open(logo_src) as im:
            if im.mode != "RGBA":
                im = im.convert("RGBA")
            for label, width in LOGO_SIZES.items():
                resized = resize_to_width(im, width)
                resized.save(OUT_DIR / f"logo-{label}.webp", "WEBP", quality=90, method=6)

    print(f"OK: versão dark — arquivos em {OUT_DIR}")


if __name__ == "__main__":
    main()
