#!/usr/bin/env python3
"""Build a labeled web-versus-Swift contact sheet for human review."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent.parent
STATES = [
    "working",
    "searching",
    "solving",
    "listening",
    "connecting",
    "weaving",
    "composing",
    "breathing",
    "shaping",
]


def placed(path: Path, dark: bool) -> Image.Image:
    source = Image.open(path).convert("RGBA")
    background = Image.new("RGBA", source.size, (16, 16, 18, 255) if dark else (250, 250, 250, 255))
    return Image.alpha_composite(background, source).convert("RGB").resize((192, 192))


def main() -> None:
    columns = [("web", False), ("swift", False), ("web", True), ("swift", True)]
    left = 110
    top = 32
    cell = 204
    sheet = Image.new("RGB", (left + cell * len(columns), top + cell * len(STATES)), "#e8e8e8")
    draw = ImageDraw.Draw(sheet)
    for column, (platform, dark) in enumerate(columns):
        draw.text((left + column * cell + 8, 8), f"{platform} {'dark' if dark else 'light'}", fill="black")
    for row, state in enumerate(STATES):
        draw.text((8, top + row * cell + 92), state, fill="black")
        for column, (platform, dark) in enumerate(columns):
            theme = "d" if dark else "l"
            path = ROOT / "build/parity" / platform / f"{state}-64-{theme}-0.6.png"
            image = placed(path, dark)
            sheet.paste(image, (left + column * cell + 6, top + row * cell + 6))
    output = ROOT / "build/parity/contact-sheet.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)
    print(output)


if __name__ == "__main__":
    main()
