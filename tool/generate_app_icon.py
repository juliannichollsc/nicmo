"""Generates the Nicmo launcher icons for Android and iOS.

The icon is the login "N" badge (light blue tile, white N, green stop dot)
inside a white circle. Same geometry as NicmoBadge in
lib/widget/shared/nicmo_logo.dart.

Run from the project root:  python3 tool/generate_app_icon.py
"""

import json
import os

from PIL import Image, ImageDraw, ImageFilter

LOGO_BLUE = (0x6C, 0xC8, 0xF2)
LOGO_BLUE_DEEP = (0x3F, 0xA9, 0xDE)
BRAND = (0x65, 0xBC, 0x4B)
GREEN = (0x41, 0x82, 0x2B)
GREEN_DEEP = (0x2D, 0x5D, 0x1D)
WHITE = (255, 255, 255)

SS = 4  # supersampling factor for smooth edges

RES = "android/app/src/main/res"
IOS = "ios/Runner/Assets.xcassets/AppIcon.appiconset"


def gradient(size, start, end):
    """Diagonal gradient from top-left (start) to bottom-right (end)."""
    n = 256
    small = Image.new("RGB", (n, n))
    for y in range(n):
        for x in range(n):
            t = (x + y) / (2 * (n - 1))
            small.putpixel(
                (x, y), tuple(round(a + (b - a) * t) for a, b in zip(start, end))
            )
    return small.resize((size, size), Image.BICUBIC)


def badge(size):
    """The N badge as an RGBA image of side [size] (with soft shadow room)."""
    s = size * SS
    tile = gradient(s, LOGO_BLUE, LOGO_BLUE_DEEP).convert("RGBA")
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, s - 1, s - 1), radius=int(s * 0.3), fill=255
    )
    tile.putalpha(mask)

    d = ImageDraw.Draw(tile)
    # Bold geometric N, centred, about the size of the 0.62 font in the app.
    h = s * 0.46
    w = s * 0.40
    stem = s * 0.105
    x0 = (s - w) / 2
    y0 = (s - h) / 2
    x1, y1 = x0 + w, y0 + h
    d.rectangle((x0, y0, x0 + stem, y1), fill=WHITE)
    d.rectangle((x1 - stem, y0, x1, y1), fill=WHITE)
    d.polygon(
        [(x0, y0), (x0 + stem * 1.25, y0), (x1, y1), (x1 - stem * 1.25, y1)],
        fill=WHITE,
    )

    # Green stop dot with a white ring, bottom-right.
    r = s * 0.08
    ring = s * 0.035
    cx = s - s * 0.13 - r
    cy = s - s * 0.13 - r
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=WHITE)
    d.ellipse(
        (cx - r + ring, cy - r + ring, cx + r - ring, cy + r - ring), fill=BRAND
    )
    return tile


def compose(canvas, badge_ratio, circle_ratio, background=None):
    """Badge centred in a white circle on [background] (None = transparent)."""
    c = canvas * SS
    if isinstance(background, Image.Image):
        img = background.resize((c, c)).convert("RGBA")
    elif background is None:
        img = Image.new("RGBA", (c, c), (0, 0, 0, 0))
    else:
        img = Image.new("RGBA", (c, c), background + (255,))
    d = ImageDraw.Draw(img)
    if circle_ratio:
        cr = c * circle_ratio / 2
        # Soft shadow under the circle.
        shadow = Image.new("RGBA", (c, c), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).ellipse(
            (c / 2 - cr, c / 2 - cr + c * 0.012, c / 2 + cr, c / 2 + cr + c * 0.012),
            fill=(0, 0, 0, 60),
        )
        img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(c * 0.012)))
        d = ImageDraw.Draw(img)
        d.ellipse((c / 2 - cr, c / 2 - cr, c / 2 + cr, c / 2 + cr), fill=WHITE + (255,))

    b = badge(int(canvas * badge_ratio))
    bs = b.size[0]
    # Shadow of the badge, like the BoxShadow in Flutter.
    shadow = Image.new("RGBA", (c, c), (0, 0, 0, 0))
    sm = Image.new("RGBA", b.size, LOGO_BLUE_DEEP + (90,))
    sm.putalpha(b.getchannel("A").point(lambda a: a * 90 // 255))
    shadow.paste(sm, ((c - bs) // 2, (c - bs) // 2 + int(bs * 0.06)), sm)
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(bs * 0.06)))
    img.alpha_composite(b, ((c - bs) // 2, (c - bs) // 2))
    return img.resize((canvas, canvas), Image.LANCZOS)


def android():
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, scale in densities.items():
        folder = f"{RES}/mipmap-{name}"
        os.makedirs(folder, exist_ok=True)
        legacy = compose(int(48 * scale), badge_ratio=0.5, circle_ratio=0.92)
        legacy.save(f"{folder}/ic_launcher.png")
        legacy.save(f"{folder}/ic_launcher_round.png")
        # Adaptive icon foreground: 108dp canvas, 66dp safe zone.
        fg = compose(int(108 * scale), badge_ratio=0.46, circle_ratio=0)
        fg.save(f"{folder}/ic_launcher_foreground.png")

    os.makedirs(f"{RES}/mipmap-anydpi-v26", exist_ok=True)
    adaptive = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
    for name in ("ic_launcher", "ic_launcher_round"):
        with open(f"{RES}/mipmap-anydpi-v26/{name}.xml", "w") as f:
            f.write(adaptive)
    with open(f"{RES}/values/ic_launcher_background.xml", "w") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
            '    <color name="ic_launcher_background">#FFFFFF</color>\n'
            "</resources>\n"
        )


def ios():
    # iOS icons must be opaque squares (the system rounds the corners): the
    # white circle sits on the app's green.
    background = gradient(1024, GREEN, GREEN_DEEP)
    master = compose(1024, badge_ratio=0.5, circle_ratio=0.84, background=background)
    master = master.convert("RGB")
    with open(f"{IOS}/Contents.json") as f:
        contents = json.load(f)
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        px = round(points * scale)
        master.resize((px, px), Image.LANCZOS).save(f"{IOS}/{image['filename']}")


def web():
    icon = compose(512, badge_ratio=0.5, circle_ratio=0.92)
    for size, name in ((192, "Icon-192.png"), (512, "Icon-512.png")):
        icon.resize((size, size), Image.LANCZOS).save(f"web/icons/{name}")
    maskable = compose(512, badge_ratio=0.42, circle_ratio=0, background=WHITE)
    for size, name in ((192, "Icon-maskable-192.png"), (512, "Icon-maskable-512.png")):
        maskable.resize((size, size), Image.LANCZOS).save(f"web/icons/{name}")
    icon.resize((32, 32), Image.LANCZOS).save("web/favicon.png")


if __name__ == "__main__":
    android()
    ios()
    if os.path.isdir("web/icons"):
        web()
    compose(512, badge_ratio=0.5, circle_ratio=0.92).save("build/nicmo_icon_preview.png")
    print("Icons generated.")
