"""アプリアイコン（1024×1024、RGB・アルファなし）を作る。

アイボリーの紙に、長辺の同じ画布を三つ、机に並べる。幅だけが号数の種別で変わる。
広い順に正方形（S）、人物（F）、海景（M）。いちばん細い海景だけ錆青。
"""

from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
OUT = ROOT / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"

SIZE = 1024
SCALE = 4
PAPER = (249, 248, 245)
INK = (26, 26, 27)
ACCENT = (74, 106, 122)

# 長辺÷短辺、墨に対する濃さ、色。左から右へ、細くなる。
FRAMES = [
    (1.00, 0.22, INK),     # S（正方形）
    (1.29, 1.00, INK),     # F（人物）
    (1.69, 1.00, ACCENT),  # M（海景）
]
CANVAS_HEIGHT = 0.36
GAP = 0.041
STROKE = 10
BASELINE = 0.665


def blend(color, opacity):
    """紙に色を薄く重ねたときの色。"""
    return tuple(int(PAPER[i] + (color[i] - PAPER[i]) * opacity) for i in range(3))


def main() -> None:
    canvas = SIZE * SCALE
    image = Image.new("RGB", (canvas, canvas), PAPER)
    draw = ImageDraw.Draw(image)

    height = CANVAS_HEIGHT * canvas
    gap = GAP * canvas
    stroke = STROKE * SCALE
    top = BASELINE * canvas - height
    bottom = BASELINE * canvas

    widths = [height / ratio for ratio, _, _ in FRAMES]
    total = sum(widths) + gap * (len(widths) - 1)
    left = (canvas - total) / 2

    for (ratio, opacity, color), width in zip(FRAMES, widths):
        draw.rectangle(
            [left, top, left + width, bottom],
            outline=blend(color, opacity),
            width=stroke,
        )
        left += width + gap

    # 机の線。三つが同じ面に立っていることを示す。
    shelf_left = (canvas - total) / 2 - 0.010 * canvas
    shelf_right = (canvas + total) / 2 + 0.010 * canvas
    draw.line(
        [(shelf_left, bottom + 0.030 * canvas), (shelf_right, bottom + 0.030 * canvas)],
        fill=blend(INK, 0.22),
        width=stroke // 3,
    )

    image = image.resize((SIZE, SIZE), Image.LANCZOS).convert("RGB")
    OUT.mkdir(parents=True, exist_ok=True)
    image.save(OUT / "AppIcon.png", "PNG")

    check = Image.open(OUT / "AppIcon.png")
    print(f"size={check.size} mode={check.mode}")
    print(f"corner={check.getpixel((4, 4))} center={check.getpixel((512, 512))}")
    assert check.size == (SIZE, SIZE), check.size
    assert check.mode == "RGB", check.mode


if __name__ == "__main__":
    main()
