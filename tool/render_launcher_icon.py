#!/usr/bin/env python3
"""Draw the Ordnance launcher mark and export Android densities.

End-on muzzle: two bore rings, six rifling grooves, one witness tick.
No filled disc and no rim, so the adaptive mask does not read as a coin.
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BG = (12, 14, 18, 255)
INK = (226, 177, 90, 255)
CLEAR = (0, 0, 0, 0)

# launcher px, adaptive foreground px
DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}


def draw_mark(size: int, color, background) -> Image.Image:
    img = Image.new("RGBA", (size, size), background)
    draw = ImageDraw.Draw(img)
    cx = cy = size / 2
    # Stay inside the adaptive safe zone (66/108 of the canvas).
    outer = size * 0.28
    inner = outer * 0.55
    stroke = max(3, int(round(size * 0.055)))
    box = lambda r: [cx - r, cy - r, cx + r, cy + r]
    draw.ellipse(box(outer), outline=color, width=stroke)
    draw.ellipse(box(inner), outline=color, width=max(1, stroke - 1))
    groove = outer * 0.86
    for i in range(6):
        start = i * 60 + 8
        draw.arc(box(groove), start=start, end=start + 16, fill=color, width=stroke)
    tick = max(2, stroke)
    draw.line(
        [(cx, cy - outer - stroke), (cx, cy - outer * 1.28)],
        fill=color,
        width=tick,
    )
    return img


def circle_crop(img: Image.Image) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse([0, 0, img.size[0] - 1, img.size[1] - 1], fill=255)
    out = Image.new("RGBA", img.size, CLEAR)
    out.paste(img, mask=mask)
    return out


def main() -> None:
    res = ROOT / "app-icon" / "res"
    master = draw_mark(512, INK, BG)
    (ROOT / "assets" / "images").mkdir(parents=True, exist_ok=True)
    master.save(ROOT / "assets" / "images" / "app-icon.png")
    for name, (launcher, foreground) in DENSITIES.items():
        mip = res / f"mipmap-{name}"
        draw = res / f"drawable-{name}"
        mip.mkdir(parents=True, exist_ok=True)
        draw.mkdir(parents=True, exist_ok=True)
        icon = draw_mark(launcher, INK, BG)
        icon.save(mip / "ic_launcher.png")
        circle_crop(icon).save(mip / "ic_launcher_round.png")
        draw_mark(foreground, INK, CLEAR).save(draw / "ic_launcher_foreground.png")
        draw_mark(foreground, (255, 255, 255, 255), CLEAR).save(
            draw / "ic_launcher_monochrome.png"
        )
    (res / "values" / "ic_launcher_colors.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FF0C0E12</color>
</resources>
"""
    )
    adaptive = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
"""
    for folder in ("mipmap-anydpi-v26",):
        d = res / folder
        d.mkdir(parents=True, exist_ok=True)
        (d / "ic_launcher.xml").write_text(adaptive)
        (d / "ic_launcher_round.xml").write_text(adaptive)
    optional = ROOT / "app-icon" / "optional"
    optional.mkdir(parents=True, exist_ok=True)
    (optional / "ic_launcher.xml").write_text(adaptive)
    (optional / "ic_launcher_round.xml").write_text(adaptive)
    print("wrote launcher assets")


if __name__ == "__main__":
    main()
