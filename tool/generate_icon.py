#!/usr/bin/env python3
"""Builds the AS Vault launcher icons from the official rose photograph.

Source : assets/icon/source_rose.jpg (dark-red rose with raindrops)
Outputs: android_overrides/res/... (adaptive + legacy + round + monochrome)
         assets/icon/app_icon*.png (full-size exports used in-app / docs)

The rose is kept intact inside Android's adaptive-icon safe zone, the
background is a darkened, blurred version of the same photograph so the
foreground fades into it seamlessly, and no text, frame or border is added.
"""
from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

SIZE = 1024
SRC = os.path.join("assets", "icon", "source_rose.jpg")
OUT_RES = os.path.join("android_overrides", "res")
OUT_ASSETS = os.path.join("assets", "icon")

# How much of the full tile the photograph occupies in the adaptive
# foreground. 0.88 keeps the bloom inside the 66 % safe circle on every mask
# shape (circle, squircle, rounded square) while still feeling generous.
ADAPTIVE_PHOTO_SCALE = 0.68
VERTICAL_SHIFT = -0.012  # the bloom sits slightly above the photo's centre


def open_square(path: str) -> Image.Image:
    image = Image.open(path).convert("RGB")
    w, h = image.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    image = image.crop((left, top, left + side, top + side))
    # The source photograph is intentionally moody; lift the shadows a little
    # so the bloom still reads on a 48 px launcher icon without losing the
    # dark, premium feel.
    image = ImageEnhance.Brightness(image).enhance(1.42)
    image = ImageEnhance.Contrast(image).enhance(1.10)
    image = ImageEnhance.Color(image).enhance(1.10)
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def cover_resize(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.LANCZOS)


def crop_fraction(image: Image.Image, fraction: float) -> Image.Image:
    side = int(image.width * fraction)
    left = (image.width - side) // 2
    top = (image.height - side) // 2
    return image.crop((left, top, left + side, top + side))


def radial_mask(size: int, center, radius: float, softness: float = 1.0) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    steps = 260
    for i in range(steps, -1, -1):
        t = i / steps
        r = radius * t
        if r <= 0:
            continue
        value = int(255 * (1.0 - t) ** (1.0 + softness))
        draw.ellipse(
            [center[0] - r, center[1] - r, center[0] + r, center[1] + r],
            fill=value,
        )
    return mask.filter(ImageFilter.GaussianBlur(size * 0.012))


def feathered_alpha(size: int, inset: int = 44) -> Image.Image:
    """Rounded-rect alpha with a soft edge, so the foreground never shows a
    hard seam against the matching blurred background."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        [inset, inset, size - inset, size - inset],
        radius=int(size * 0.20),
        fill=255,
    )
    return mask.filter(ImageFilter.GaussianBlur(size * 0.035))


def make_background(photo: Image.Image) -> Image.Image:
    bg = photo.filter(ImageFilter.GaussianBlur(52))
    bg = ImageEnhance.Brightness(bg).enhance(0.38)
    bg = ImageEnhance.Color(bg).enhance(0.90)

    # Darken the corners so any launcher mask shape stays near-black.
    vignette = radial_mask(SIZE, (SIZE // 2, SIZE // 2), SIZE * 0.74, softness=1.5)
    dark = Image.new("RGB", (SIZE, SIZE), (4, 3, 5))
    bg = Image.composite(bg, dark, vignette)

    # A restrained red halo behind the bloom ties the foreground into the
    # backdrop and keeps the rose silhouette readable at small sizes.
    halo = radial_mask(
        SIZE,
        (SIZE // 2, int(SIZE * (0.5 + VERTICAL_SHIFT))),
        SIZE * 0.40,
        softness=1.25,
    )
    warm = Image.blend(bg, Image.new("RGB", (SIZE, SIZE), (92, 17, 26)), 0.35)
    bg = Image.composite(warm, bg, halo)
    return bg


def make_foreground(photo: Image.Image) -> Image.Image:
    content_size = int(SIZE * ADAPTIVE_PHOTO_SCALE)
    content = photo.resize((content_size, content_size), Image.LANCZOS)
    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    x = (SIZE - content_size) // 2
    y = (SIZE - content_size) // 2 + int(SIZE * VERTICAL_SHIFT)
    content = content.convert("RGBA")
    content.putalpha(feathered_alpha(content_size, inset=int(content_size * 0.015)))
    fg.alpha_composite(content, (x, y))
    return fg


def compose_legacy(photo: Image.Image, circle: bool = False) -> Image.Image:
    bg = make_background(photo).convert("RGBA")
    content = crop_fraction(photo, 0.94).resize((SIZE, SIZE), Image.LANCZOS).convert("RGBA")
    bg.alpha_composite(content, (0, int(SIZE * VERTICAL_SHIFT)))

    mask = Image.new("L", (SIZE, SIZE), 0)
    draw = ImageDraw.Draw(mask)
    if circle:
        draw.ellipse([2, 2, SIZE - 3, SIZE - 3], fill=255)
    else:
        draw.rounded_rectangle(
            [2, 2, SIZE - 3, SIZE - 3],
            radius=int(SIZE * 0.22),
            fill=255,
        )
    bg.putalpha(mask)
    return bg


def save(image: Image.Image, path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path, optimize=True)
    print("wrote", path, image.size)


def main():
    if not os.path.exists(SRC):
        raise SystemExit(f"missing source photo: {SRC}")
    photo = open_square(SRC)

    background = make_background(photo)
    foreground = make_foreground(photo)

    save(background.convert("RGBA"), os.path.join(OUT_RES, "drawable-nodpi", "ic_launcher_background.png"))
    save(foreground, os.path.join(OUT_RES, "drawable-nodpi", "ic_launcher_foreground.png"))

    adaptive = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""
    anydpi = os.path.join(OUT_RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        with open(os.path.join(anydpi, name), "w", encoding="utf-8") as handle:
            handle.write(adaptive)
        print("wrote", os.path.join(anydpi, name))

    legacy = compose_legacy(photo, circle=False)
    round_icon = compose_legacy(photo, circle=True)

    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, px in densities.items():
        save(legacy.resize((px, px), Image.LANCZOS), os.path.join(OUT_RES, folder, "ic_launcher.png"))
        save(round_icon.resize((px, px), Image.LANCZOS), os.path.join(OUT_RES, folder, "ic_launcher_round.png"))

    # Full-size exports: in-app wordmark + source layers for the report.
    app_icon = compose_legacy(photo, circle=False)
    save(app_icon.resize((512, 512), Image.LANCZOS), os.path.join(OUT_ASSETS, "app_icon.png"))
    save(foreground, os.path.join(OUT_ASSETS, "app_icon_foreground.png"))
    save(background.convert("RGBA"), os.path.join(OUT_ASSETS, "app_icon_background.png"))
    save(legacy, os.path.join(OUT_ASSETS, "app_icon_1024.png"))

    # Contact sheet for quick visual review.
    sheet = Image.new("RGB", (SIZE * 3 + 80, SIZE + 40), (12, 10, 13))
    sheet.paste(legacy.resize((SIZE, SIZE)), (20, 20), legacy.resize((SIZE, SIZE)))
    sheet.paste(round_icon.resize((SIZE, SIZE)), (SIZE + 40, 20), round_icon.resize((SIZE, SIZE)))
    preview_bg = background.convert("RGBA")
    preview_bg.alpha_composite(foreground, (0, 0))
    sheet.paste(preview_bg.convert("RGB"), (SIZE * 2 + 60, 20))
    save(sheet, os.path.join(OUT_ASSETS, "icon_preview.png"))


if __name__ == "__main__":
    main()
