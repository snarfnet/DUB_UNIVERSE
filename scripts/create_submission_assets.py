from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
GEN_DIR = Path.home() / ".codex" / "generated_images" / "019e3550-6201-7600-a7c1-e2a0b6e93398"
ICON_SOURCE = GEN_DIR / "ig_0e2fa98022d4c918016a09ba409b5c8191a9015048b56e9248.png"
SCREEN_SOURCE = GEN_DIR / "ig_0e2fa98022d4c918016a09ba84a70c8191b4fcef81ce3b06c6.png"

ASSET_ROOT = ROOT / "ASC_Submission_Assets"
ICON_OUT = ASSET_ROOT / "icon" / "dub-universe-icon-1024.png"
SCREEN_OUT = ASSET_ROOT / "screenshots"
APPICON_SET = ROOT / "Assets.xcassets" / "AppIcon.appiconset"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def fit_cover(src: Image.Image, size: tuple[int, int]) -> Image.Image:
    return ImageOps.fit(src.convert("RGB"), size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def draw_panel(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill=(13, 13, 12, 218), outline=(166, 82, 31, 155)) -> None:
    draw.rounded_rectangle(box, radius=28, fill=fill, outline=outline, width=3)


def draw_text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, size: int, fill=(238, 222, 194), bold=False, anchor=None) -> None:
    draw.text(xy, text, font=font(size, bold), fill=fill, anchor=anchor)


def waveform(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color=(219, 112, 45), width=5) -> None:
    x0, y0, x1, y1 = box
    mid = (y0 + y1) / 2
    pts = []
    for i in range(96):
        t = i / 95
        x = x0 + t * (x1 - x0)
        amp = math.sin(t * math.pi) * (y1 - y0) * 0.38
        y = mid + math.sin(t * math.pi * 10.0) * amp * 0.55 + math.sin(t * math.pi * 23.0) * amp * 0.22
        pts.append((x, y))
    draw.line(pts, fill=color, width=width, joint="curve")


def sequencer(draw: ImageDraw.ImageDraw, origin: tuple[int, int], cell: int, rows: int, cols: int, active: set[tuple[int, int]]) -> None:
    ox, oy = origin
    for r in range(rows):
        for c in range(cols):
            x = ox + c * (cell + 12)
            y = oy + r * (cell + 12)
            fill = (34, 33, 30, 230)
            outline = (112, 72, 42, 130)
            if (r, c) in active:
                fill = (207, 89, 33, 235)
                outline = (244, 171, 85, 210)
            draw.rounded_rectangle((x, y, x + cell, y + cell), radius=9, fill=fill, outline=outline, width=2)


def knob(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, label: str, value: float) -> None:
    cx, cy = center
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(29, 28, 25, 245), outline=(178, 88, 38, 170), width=4)
    angle = -135 + value * 270
    px = cx + math.cos(math.radians(angle)) * radius * 0.68
    py = cy + math.sin(math.radians(angle)) * radius * 0.68
    draw.line((cx, cy, px, py), fill=(240, 153, 71), width=7)
    draw_text(draw, (cx, cy + radius + 32), label, 31, fill=(224, 203, 174), bold=True, anchor="mm")


def make_screen(size: tuple[int, int], variant: int) -> Image.Image:
    bg = fit_cover(Image.open(SCREEN_SOURCE), size)
    bg = ImageEnhance.Contrast(bg).enhance(1.15)
    bg = ImageEnhance.Color(bg).enhance(0.78)
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    w, h = size

    d.rectangle((0, 0, w, h), fill=(0, 0, 0, 64))
    d.rectangle((0, 0, w, int(h * 0.28)), fill=(0, 0, 0, 98))
    d.rectangle((0, int(h * 0.78), w, h), fill=(0, 0, 0, 88))

    margin = int(w * 0.08)
    draw_text(d, (margin, 168), "DUB UNIVERSE", 82, bold=True)
    draw_text(d, (margin, 258), "Rusted dub techno generator", 38, fill=(218, 178, 130))

    if variant == 1:
        draw_panel(d, (margin, 420, w - margin, 940))
        draw_text(d, (margin + 44, 486), "ANALYZE AUDIO", 45, bold=True)
        waveform(d, (margin + 54, 605, w - margin - 54, 800), width=7)
        draw_text(d, (margin + 44, 852), "BPM 126   BASE G   COLD / DEEP", 33, fill=(220, 192, 151))
        draw_panel(d, (margin, 1030, w - margin, 1710))
        draw_text(d, (margin + 44, 1096), "GENERATE 5 TRACKS", 45, bold=True)
        active = {(0, 0), (0, 4), (0, 8), (0, 12), (1, 2), (1, 10), (2, 5), (2, 13), (3, 1), (3, 9)}
        sequencer(d, (margin + 54, 1218), 45, 4, 14, active)
        draw_text(d, (margin, h - 265), "Heavy bass. Metallic delays. One tap export.", 43, bold=True)
    elif variant == 2:
        draw_panel(d, (margin, 430, w - margin, 1290))
        draw_text(d, (margin + 44, 500), "MACRO CONTROL", 45, bold=True)
        positions = [
            (margin + 170, 700, "DEPTH", 0.82),
            (w // 2, 700, "DECAY", 0.66),
            (w - margin - 170, 700, "TAPE", 0.74),
            (margin + 170, 1010, "WOBBLE", 0.58),
            (w // 2, 1010, "SPACE", 0.88),
            (w - margin - 170, 1010, "DRIVE", 0.7),
        ]
        for x, y, label, value in positions:
            knob(d, (x, y), 76, label, value)
        draw_panel(d, (margin, 1390, w - margin, 1810))
        draw_text(d, (margin + 44, 1462), "EMOTIONAL PRESETS", 42, bold=True)
        for i, name in enumerate(["Deep", "Cold", "Fog", "Pulse"]):
            x = margin + 54 + i * ((w - margin * 2 - 108) // 4)
            d.rounded_rectangle((x, 1580, x + 205, 1682), radius=19, fill=(45, 36, 31, 235), outline=(179, 83, 35), width=2)
            draw_text(d, (x + 102, 1631), name.upper(), 27, bold=True, anchor="mm")
        draw_text(d, (margin, h - 265), "Shape the mood like hardware.", 48, bold=True)
    else:
        draw_panel(d, (margin, 420, w - margin, 1120))
        draw_text(d, (margin + 44, 492), "LIVE SEQUENCER", 45, bold=True)
        active = {(0, 0), (0, 3), (0, 6), (0, 11), (0, 15), (1, 4), (1, 12), (2, 7), (2, 14), (3, 2), (3, 10), (4, 5), (4, 13)}
        sequencer(d, (margin + 54, 630), 41, 5, 16, active)
        draw_panel(d, (margin, 1225, w - margin, 1765))
        draw_text(d, (margin + 44, 1295), "MIDI EXPORT", 45, bold=True)
        waveform(d, (margin + 54, 1415, w - margin - 54, 1588), color=(236, 151, 72), width=6)
        draw_text(d, (margin + 44, 1640), "Bass / Chords / Echo / Texture / Drums", 32, fill=(220, 192, 151))
        draw_text(d, (margin, h - 265), "Build a track, then take it anywhere.", 45, bold=True)

    d.rounded_rectangle((margin, h - 168, w - margin, h - 86), radius=18, fill=(198, 77, 26, 235))
    draw_text(d, (w // 2, h - 127), "START GENERATING", 32, fill=(24, 16, 12), bold=True, anchor="mm")
    return Image.alpha_composite(bg.convert("RGBA"), overlay).convert("RGB")


def main() -> None:
    ICON_OUT.parent.mkdir(parents=True, exist_ok=True)
    SCREEN_OUT.mkdir(parents=True, exist_ok=True)
    APPICON_SET.mkdir(parents=True, exist_ok=True)

    icon = fit_cover(Image.open(ICON_SOURCE), (1024, 1024))
    icon.save(ICON_OUT)
    for size in [40, 58, 60, 80, 87, 120, 180, 1024]:
        icon.resize((size, size), Image.Resampling.LANCZOS).save(APPICON_SET / f"app-icon-{size}.png")

    for variant in [1, 2, 3]:
        full = make_screen((1290, 2796), variant)
        full.save(SCREEN_OUT / f"iphone_6_7_{variant:02d}.png", quality=95)
        ImageOps.fit(full, (1242, 2688), method=Image.Resampling.LANCZOS).save(SCREEN_OUT / f"iphone_6_5_{variant:02d}.png", quality=95)


if __name__ == "__main__":
    main()
