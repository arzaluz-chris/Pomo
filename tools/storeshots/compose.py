"""Compose App Store screenshots for Pomo.

Usage: python3 -I compose.py RAW_DIR OUT_DIR
RAW_DIR holds raw simulator captures named {lang}_{size}_{shot}.png (size: 69 or 63) and
{lang}_watch_{shot}.png. Output: exact App Store sizes, RGB (no alpha).
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

RAW, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)

BEZELS = "/Users/christianarzaluz/Documents/MemoMed-bezels-apple/iPhone-18"
DEVICES = {
    # canvas size, bezel file, screen rect inside the bezel (x, y, w, h)
    "69": ((1320, 2868), f"{BEZELS}/iPhone 18 Pro Max/iPhone 18 Pro Max - Silver - Portrait.png", (75, 66, 1320, 2868)),
    "63": ((1206, 2622), f"{BEZELS}/iPhone 18 Pro/iPhone 18 Pro - Silver - Portrait.png", (72, 69, 1206, 2622)),
}
FONT_BLACK = "/Library/Fonts/SF-Pro-Rounded-Black.otf"
FONT_SEMI = "/Library/Fonts/SF-Pro-Rounded-Semibold.otf"

CREAM = (255, 244, 230)
PAGE = (251, 241, 230)
INK = (43, 23, 20)
TOMATO = (201, 59, 43)
TEAL = (23, 121, 111)
INDIGO = (82, 87, 194)
MUTED = (122, 94, 85)

# shot id -> background, headline color, subline color, copy per language
SHOTS = [
    ("timer", TOMATO, CREAM, (255, 225, 210), {
        "es": ("Enfócate de verdad", "Un temporizador de cocina que gira contigo"),
        "en": ("Focus for real", "A kitchen timer that turns with you"),
    }),
    ("break", TEAL, CREAM, (214, 241, 236), {
        "es": ("Descansa a tiempo", "Pausas cortas y largas, en su color"),
        "en": ("Rest on time", "Short and long breaks, each in its color"),
    }),
    ("stats", PAGE, INK, MUTED, {
        "es": ("Mira tu progreso", "Pomodoros, enfoque y racha de cada día"),
        "en": ("See your progress", "Pomodoros, focus time and your daily streak"),
    }),
    ("settings", PAGE, INK, MUTED, {
        "es": ("A tu ritmo", "Ajusta sesiones, ciclos y alertas"),
        "en": ("Your rhythm", "Tune sessions, cycles and alerts"),
    }),
    ("watch", INDIGO, CREAM, (224, 225, 250), {
        "es": ("También en tu muñeca", "Apple Watch sincronizado con tu iPhone"),
        "en": ("On your wrist too", "Apple Watch in sync with your iPhone"),
    }),
]


def fit_font(path, text, max_width, start):
    size = start
    while size > 20:
        font = ImageFont.truetype(path, size)
        if font.getlength(text) <= max_width:
            return font
        size -= 4
    return ImageFont.truetype(path, size)


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return mask


def phone_mockup(raw_path, device):
    (_, bezel_path, (sx, sy, sw, sh)) = device
    bezel = Image.open(bezel_path).convert("RGBA")
    shot = Image.open(raw_path).convert("RGB").resize((sw, sh), Image.LANCZOS)
    layer = Image.new("RGBA", bezel.size, (0, 0, 0, 0))
    layer.paste(shot, (sx, sy), rounded_mask((sw, sh), int(sw * 0.13)))
    layer.alpha_composite(bezel)
    return layer


def watch_mockup(raw_path, width):
    shot = Image.open(raw_path).convert("RGB")
    scale = width / shot.width
    shot = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)
    border = int(width * 0.075)
    body = Image.new("RGBA", (shot.width + border * 2, shot.height + border * 2), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle([0, 0, body.width - 1, body.height - 1],
                                           radius=int(body.width * 0.28), fill=(28, 26, 26, 255))
    body.paste(shot, (border, border), rounded_mask(shot.size, int(shot.width * 0.24)))
    return body


def compose(lang, size_key, shot):
    shot_id, bg, head_color, sub_color, copy = shot
    device = DEVICES[size_key]
    (W, H) = device[0]
    canvas = Image.new("RGBA", (W, H), bg + (255,))
    draw = ImageDraw.Draw(canvas)

    headline, subline = copy[lang]
    margin = int(W * 0.08)
    head_font = fit_font(FONT_BLACK, headline, W - margin * 2, int(W * 0.105))
    sub_font = fit_font(FONT_SEMI, subline, W - margin * 2, int(W * 0.045))
    top = int(H * 0.065)
    draw.text((W / 2, top), headline, font=head_font, fill=head_color, anchor="mt")
    head_h = head_font.getbbox(headline)[3]
    draw.text((W / 2, top + head_h + int(H * 0.018)), subline, font=sub_font, fill=sub_color, anchor="mt")

    raw = os.path.join(RAW, f"{lang}_{size_key}_{'timer' if shot_id == 'watch' else shot_id}.png")
    phone = phone_mockup(raw, device)
    is_watch = shot_id == "watch"
    target_w = int(W * (0.70 if is_watch else 0.84))
    phone = phone.resize((target_w, int(phone.height * target_w / phone.width)), Image.LANCZOS)
    py = int(H * 0.215)
    px = int(W * 0.05) if is_watch else (W - phone.width) // 2
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_shape = Image.new("RGBA", phone.size, (0, 0, 0, 0))
    shadow_shape.paste((0, 0, 0, 70), (0, 0), phone.split()[-1])
    shadow.paste(shadow_shape, (px, py + 24), shadow_shape)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(28)))
    canvas.alpha_composite(phone, (px, py))

    if shot_id == "watch":
        watch_raw = os.path.join(RAW, f"{lang}_watch_timer.png")
        watch = watch_mockup(watch_raw, int(W * 0.40))
        wx = W - watch.width - int(W * 0.035)
        wy = int(H * 0.52)
        wshadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        wshape = Image.new("RGBA", watch.size, (0, 0, 0, 0))
        wshape.paste((0, 0, 0, 90), (0, 0), watch.split()[-1])
        wshadow.paste(wshape, (wx, wy + 18), wshape)
        canvas.alpha_composite(wshadow.filter(ImageFilter.GaussianBlur(24)))
        canvas.alpha_composite(watch, (wx, wy))

    out = os.path.join(OUT, f"{lang}", f"iphone-{size_key}")
    os.makedirs(out, exist_ok=True)
    index = [s[0] for s in SHOTS].index(shot_id) + 1
    canvas.convert("RGB").save(os.path.join(out, f"{index:02d}-{shot_id}.png"))


for lang in ("es", "en"):
    for size_key in DEVICES:
        for shot in SHOTS:
            raw = os.path.join(RAW, f"{lang}_{size_key}_{'timer' if shot[0] == 'watch' else shot[0]}.png")
            if os.path.exists(raw):
                compose(lang, size_key, shot)
    # Apple Watch: raw captures at the device size, without alpha
    for name in sorted(os.listdir(RAW)):
        if name.startswith(f"{lang}_watch_"):
            out = os.path.join(OUT, lang, "watch-46")
            os.makedirs(out, exist_ok=True)
            Image.open(os.path.join(RAW, name)).convert("RGB").save(os.path.join(out, name.replace(f"{lang}_watch_", "")))
print("done")
