#!/usr/bin/env python3
"""Regenerates the PWA / favicon set in web/icons from the in-app dice mark.

The icon is the same object the Roll screen draws (lib/widgets/dice_tile.dart):
a rounded surface-coloured square showing the five-face in green. Proportions
below are that widget's, expressed as fractions of the 120 px tile so they
scale to any icon size.

Requires Pillow.  Run from the repo root:

    python3 tool/generate_icons.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

# Tokens — keep in sync with lib/theme/app_tokens.dart.
BACKGROUND = (0x10, 0x12, 0x16, 0xFF)  # AppColors.background
SURFACE = (0x18, 0x1B, 0x21, 0xFF)  # AppColors.surface
GREEN = (0x35, 0xD0, 0x7F, 0xFF)  # AppColors.green
BORDER_STRONG = (0xFF, 0xFF, 0xFF, 0x1F)  # AppColors.borderStrong (white 12%)

# DiceTile geometry, as fractions of the 120 px tile.
RADIUS = 28 / 120  # AppRadii.rDice
PIP = 14 / 120  # pip diameter
GAP = 6 / 120  # gap between pips
FIVE_FACE = {(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)}

SS = 4  # supersampling factor, for smooth curves at small sizes

OUT = Path(__file__).resolve().parent.parent / "web"


def render(size, *, inset=0.0, backdrop=None, pip_scale=1.0, border=True):
    """Draws the dice mark at `size` px.

    `inset` shrinks the die as a fraction of the canvas per side — used to keep
    maskable icons inside the safe zone. `backdrop` fills the full canvas behind
    the die; leave it None to get transparent corners.
    """
    canvas = size * SS
    img = Image.new("RGBA", (canvas, canvas), backdrop or (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    die = canvas * (1 - 2 * inset)
    origin = (canvas - die) / 2
    box = (origin, origin, origin + die, origin + die)
    radius = die * RADIUS
    draw.rounded_rectangle(box, radius=radius, fill=SURFACE)

    # The hairline is white at 12%. ImageDraw replaces pixels instead of
    # blending them, so it goes on its own layer and gets composited — drawn
    # directly it would punch a translucent slot through the icon.
    if border:
        overlay = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
        ImageDraw.Draw(overlay).rounded_rectangle(
            box,
            radius=radius,
            outline=BORDER_STRONG,
            width=max(1, round(die * 0.008)),
        )
        img = Image.alpha_composite(img, overlay)
        draw = ImageDraw.Draw(img)

    pip = die * PIP * pip_scale
    step = pip + die * GAP * pip_scale
    grid = 3 * pip + 2 * (die * GAP * pip_scale)
    left = top = origin + (die - grid) / 2
    for col, row in FIVE_FACE:
        x, y = left + col * step, top + row * step
        draw.ellipse((x, y, x + pip, y + pip), fill=GREEN)

    return img.resize((size, size), Image.LANCZOS)


def save(img, *path):
    target = OUT.joinpath(*path)
    target.parent.mkdir(parents=True, exist_ok=True)
    img.save(target)
    print(f"{target.relative_to(OUT.parent)}  {target.stat().st_size / 1024:.1f} KB")


def main():
    # "any" icons: the die fills the canvas, corners stay transparent.
    for size in (192, 512):
        save(render(size), "icons", f"Icon-{size}.png")

    # Maskable icons: launchers crop to a circle of 80% diameter, so the die is
    # inset and the corners it vacates are filled with the app background.
    for size in (192, 512):
        save(
            render(size, inset=0.14, backdrop=BACKGROUND),
            "icons",
            f"Icon-maskable-{size}.png",
        )

    # iOS applies its own superellipse mask and dislikes transparency, so this
    # one is a full-bleed square.
    save(
        render(180, backdrop=SURFACE, border=False),
        "icons",
        "apple-touch-icon-180.png",
    )

    # Favicons: pips are enlarged because the mark is read at 16 px.
    for size in (32, 96):
        name = "favicon.png" if size == 32 else f"favicon-{size}.png"
        save(render(size, pip_scale=1.18, border=False), name)


if __name__ == "__main__":
    main()
