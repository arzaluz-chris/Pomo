"""Build the "Pomo para App Store" page: template.html + captures -> a folder ready to publish.

usage: python3 -I build.py RAW_DIR DUO_DIR OUT_DIR
  RAW_DIR  capture.sh output: RAW_DIR/<device>/<lang>/<mode>/NN_name.png (device: iphone, duo-folded)
           plus RAW_DIR/watch/<lang>/watch.png (raw Apple Watch capture, 416x496)
  DUO_DIR  iPhone Duo inner-screen captures, same layout (duo-unfolded, duo-unfolded-portrait), optional:
           the inner screen needs the simulator unfolded by hand, so these are taken separately
  OUT_DIR  index.html, shots/, thumbs/ (bezels are not built here: Apple's frames are copied into the
           page from the MemoMed page when publishing, never stored in this public repo)

The page is a copy of MemoMed's store page (MemoMed repo, artifacts/store-screenshots/.../store-art)
adapted to Pomo: "Cocina" colors, rounded type, Spanish and English, the Apple Watch next to the
iPhone, and no iPad (Pomo runs on iPhone, iPhone Duo and Apple Watch).
"""
import json
import os
import shutil
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RAW, DUO, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
LANGS, MODES = ("es", "en"), ("light", "dark")
THUMB_H = 240

CAPTIONS = {
    "es": {
        "timer": ["Enfócate de verdad", "Un temporizador de cocina que gira contigo"],
        "adjust": ["Ajusta el tiempo con un dedo", "Mantén y desliza: sientes cada minuto"],
        "break": ["Descansa a tiempo", "Pausas cortas y largas, cada una en su color"],
        "stats": ["Mira tu progreso", "Pomodoros, enfoque y racha de cada día"],
        "settings": ["A tu ritmo", "Ajusta sesiones, ciclos y alertas"],
        "watch": ["También en tu muñeca", "Apple Watch sincronizado con tu iPhone"],
    },
    "en": {
        "timer": ["Focus for real", "A kitchen timer that turns with you"],
        "adjust": ["Set the time with one finger", "Hold and slide: feel every minute"],
        "break": ["Rest on time", "Short and long breaks, each in its own color"],
        "stats": ["See your progress", "Pomodoros, focus time and your daily streak"],
        "settings": ["Your rhythm", "Tune sessions, cycles and alerts"],
        "watch": ["On your wrist too", "Apple Watch in sync with your iPhone"],
    },
}
SCREEN_BG = {"timer": "tomate", "adjust": "tomate", "break": "teal", "stats": "crema", "settings": "crema", "watch": "indigo"}

NOTE = "Marco oficial de Apple (Apple Design Resources). Uso: maquetas para App Store."
DUO_BEZ = [("night-sky", "Night Sky"), ("star-white", "Star White")]


def bezels(prefix, colors, hole):
    return [{"id": c, "name": n, "file": f"{prefix}-{c}.png", "hole": hole} for c, n in colors]


DEVICES = [
    dict(id="iphone", name="iPhone 6.9″", slot="App Store · iPhone 6.9″", out=[1320, 2868], frame="phone", shots="iphone",
         defaults=["timer", "adjust", "break", "stats", "settings", "watch"],
         bezels=bezels("iphone", [("silver", "Plata"), ("black", "Negro"), ("glacier", "Glaciar"), ("burgundy", "Vino")], [75, 66, 1320, 2868]),
         bezelNote=NOTE + " iPhone 18 Pro Max. App Store Connect reduce estas imágenes para los iPhone más pequeños."),
    dict(id="duo-cerrado", name="Dúo · cerrado", slot="App Store · iPhone Duo, exterior", out=[1398, 2034], frame="duoClosed",
         shots="duo-folded", defaults=["timer@libro", "adjust@cerrado", "stats@abierto", "break@cerrado", "settings@abierto"],
         bezels=bezels("duo-closed", DUO_BEZ, [88, 80, 1398, 2034]), bezelNote=NOTE + " iPhone Duo cerrado."),
    dict(id="duo-abierto", name="Dúo · abierto", slot="App Store · iPhone Duo, interior", out=[2853, 2007], frame="duoOpen",
         shots="duo-unfolded", defaults=[], bezels=bezels("duo-open", DUO_BEZ, [120, 120, 2853, 2007]),
         bezelNote=NOTE + " iPhone Duo abierto, horizontal."),
    dict(id="duo-libro", name="Dúo · libro (L)", slot="App Store · iPhone Duo, interior", out=[2007, 2853], frame="duoBook",
         shots="duo-unfolded-portrait", defaults=[], bezels=bezels("duo-book", DUO_BEZ, [120, 120, 2007, 2853]),
         bezelNote=NOTE + " Doblado en «L»: el temporizador arriba y los controles abajo, como en la app.",
         missing="Falta la captura del Dúo abierto en vertical."),
]


def copy_set(src_root, key, out_key=None):
    """Copies <src_root>/<key>/<lang>/<mode>/*.png without alpha; returns {lang: {mode: {...}}}."""
    out_key = out_key or key
    found = {}
    for lang in LANGS:
        for mode in MODES:
            src = os.path.join(src_root, key, lang, mode)
            if not os.path.isdir(src):
                continue
            names = sorted(f[:-4] for f in os.listdir(src) if f.endswith(".png"))
            if not names:
                continue
            dst = os.path.join(OUT, "shots", out_key, lang, mode)
            os.makedirs(dst, exist_ok=True)
            thumbs = []
            for name in names:
                im = Image.open(os.path.join(src, name + ".png")).convert("RGB")
                im.save(os.path.join(dst, name + ".png"), optimize=True)
                thumbs.append(im.resize((round(im.width * THUMB_H / im.height), THUMB_H), Image.LANCZOS))
            tw = thumbs[0].width
            sprite = Image.new("RGB", (tw * len(thumbs), THUMB_H), (236, 220, 203))
            for i, t in enumerate(thumbs):
                sprite.paste(t.resize((tw, THUMB_H)), (i * tw, 0))
            os.makedirs(os.path.join(OUT, "thumbs"), exist_ok=True)
            sprite.save(os.path.join(OUT, "thumbs", f"{out_key}-{lang}-{mode}.jpg"), quality=82)
            found.setdefault(lang, {})[mode] = {"names": names, "tw": tw, "th": THUMB_H}
    return found


shutil.rmtree(OUT, ignore_errors=True)
os.makedirs(OUT)

# The "watch" image is the iPhone timer with the Watch in front of it
for lang in LANGS:
    for mode in MODES:
        d = os.path.join(RAW, "iphone", lang, mode)
        if os.path.exists(os.path.join(d, "01_timer.png")):
            shutil.copy(os.path.join(d, "01_timer.png"), os.path.join(d, "06_watch.png"))

shots = {"iphone": copy_set(RAW, "iphone"), "duo-folded": copy_set(RAW, "duo-folded")}
if DUO and os.path.isdir(DUO):
    for key in ("duo-unfolded", "duo-unfolded-portrait"):
        got = copy_set(DUO, key)
        for lang, modes in got.items():
            shots.setdefault(key, {}).setdefault(lang, {}).update(modes)

watch = {}
for lang in LANGS:
    src = os.path.join(RAW, "watch", lang, "watch.png")
    if os.path.exists(src):
        os.makedirs(os.path.join(OUT, "shots", "watch"), exist_ok=True)
        Image.open(src).convert("RGB").save(os.path.join(OUT, "shots", "watch", f"{lang}.png"))
        watch[lang] = f"shots/watch/{lang}.png"

config = dict(store="appstore", prefix="pomo_appstore", max=10,
              limitNote="App Store Connect admite de 1 a 10 imágenes por tamaño; las descargas son PNG de 24 bits sin transparencia. "
                        "Las del Apple Watch se suben tal cual salen del reloj (416×496), sin marco.",
              devices=DEVICES, shots=shots, watch=watch)
page = open(os.path.join(HERE, "template.html")).read()
page = (page.replace("__CONFIG__", json.dumps(config, ensure_ascii=False))
            .replace("__CAPTIONS__", json.dumps(CAPTIONS, ensure_ascii=False))
            .replace("__SCREEN_BG__", json.dumps(SCREEN_BG)))
open(os.path.join(OUT, "index.html"), "w").write(page)
count = sum(len(files) for _, _, files in os.walk(OUT))
print("built", OUT, count, "files")
