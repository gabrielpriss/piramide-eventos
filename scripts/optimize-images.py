#!/usr/bin/env python3
"""Gera WebP redimensionadas para a versão dark (produção)."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "img"

GENERAL_SRC = ROOT / "assets" / "FOTOS PRIME"
GENERAL_USED = [
    "AR2A0823.jpg",
    "IMG_1747.jpg",
    "IMG_9853.JPG",
    "BL7A8780.jpg",
    "AR2A0826.jpg",
    "IMG_9851.JPG",
    "BL7A8783.jpg",
    "BL7A8787.jpg",
]

DEBUT_SRC = ROOT / "assets" / "15 anos FOTOS PRIME"
DEBUT_SECTION_SIZES = {
    "BFL09792": ("lg", "md", "sm"),
    "BFL09968": ("lg", "md", "sm"),
}

SIZES_BY_STEM = {
    "AR2A0823": ("xl", "lg", "md", "sm"),
    "IMG_1747": ("lg", "md", "sm"),
    "BL7A8780": ("lg", "md"),
    "BL7A8783": ("lg", "md", "sm"),
    "IMG_9853": ("lg",),
    "AR2A0826": ("lg",),
    "IMG_9851": ("lg",),
    "BL7A8787": ("lg",),
}

RENAME_MAP = {
    # FOTOS PRIME
    "AR2A0823": "salao-piramide-pista-danca",
    "AR2A0826": "lustre-cristal-mesa-doces-espelhada",
    "BL7A8780": "salao-formatura-painel-led",
    "BL7A8783": "salao-corporativo-mesas-redondas",
    "BL7A8787": "hall-entrada-lounge",
    "IMG_1747": "sala-festa-lustre-cristal-roxo",
    "IMG_9851": "mesa-bolo-50anos-espelhada",
    "IMG_9853": "mesa-jantar-flores-azuis",
    # 15 anos FOTOS PRIME
    "BFL09844": "entrada-wonderland-personagens",
    "BFL09800": "porta-entrada-wonderland",
    "BFL09784": "painel-floral-cogumelos-wonderland",
    "BFL09792": "salao-15anos-mesas-cadeiras",
    "BFL09968": "salao-15anos-pista-iluminada-azul",
    "BFL09778": "mesa-doces-orquideas-bolo",
    "BFL09831": "mesa-doces-lustre-cristal",
    "BFL09837": "lustre-cristal-mesa-bolo-15anos",
    "BFL09852": "bolo-topo-15-doces-finos",
    "BFL09783": "mesa-drinks-cardapio-festa",
    "BFL09866": "palco-led-pista-danca",
    "BFL01062": "cerimonia-homenagem-pista",
    "BFL00780": "valsa-pai-debutante",
    "BFL00725": "valsa-emocionante-debutante",
    "BFL00677": "debutante-pista-hexagonal",
    "BFL01671": "pista-convidados-bastoes-luminosos",
    "BFL02186": "efeito-fumaca-pista",
}

SIZE_WIDTH = {"xl": 1600, "lg": 1200, "md": 800, "sm": 400}
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


def debut_images() -> list[str]:
    return sorted(
        p.name
        for p in DEBUT_SRC.iterdir()
        if p.is_file() and p.suffix.lower() in (".jpg", ".jpeg")
    )


def process_batch(
    src_dir: Path,
    names: list[str],
    sizes: dict[str, tuple[str, ...]] | None = None,
    default: tuple[str, ...] = ("lg",),
) -> None:
    sizes = sizes or {}
    for name in names:
        src = src_dir / name
        if not src.exists():
            raise FileNotFoundError(src)
        stem = Path(name).stem
        out_stem = RENAME_MAP.get(stem, stem)
        labels = sizes.get(stem, SIZES_BY_STEM.get(stem, default))
        with Image.open(src) as im:
            for label in labels:
                save_webp(
                    resize_to_width(im, SIZE_WIDTH[label]),
                    OUT_DIR / f"{out_stem}-{label}.webp",
                )


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    process_batch(GENERAL_SRC, GENERAL_USED)

    debut = debut_images()
    if not debut:
        raise FileNotFoundError(f"Nenhuma foto em {DEBUT_SRC}")
    process_batch(DEBUT_SRC, debut, DEBUT_SECTION_SIZES, default=("lg", "md", "sm"))

    logo_src = ROOT / "assets" / "logoTransparente.png"
    if logo_src.exists():
        with Image.open(logo_src) as im:
            if im.mode != "RGBA":
                im = im.convert("RGBA")
            for label, width in LOGO_SIZES.items():
                resized = resize_to_width(im, width)
                resized.save(OUT_DIR / f"logo-piramide-{label}.webp", "WEBP", quality=90, method=6)

    print(f"OK: {len(debut)} fotos de 15 anos + gerais — arquivos em {OUT_DIR}")


if __name__ == "__main__":
    main()
