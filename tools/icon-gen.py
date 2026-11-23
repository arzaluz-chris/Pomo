import json, math, os, sys
OUT = sys.argv[1]
TOMATO, CREAM, INK, LEAF, BAND = "#C93B2B", "#FFF4E6", "#2B1714", "#2F9E62", "#F4C3B4"
def svg(body, defs=""):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024"><defs>{defs}</defs>{body}</svg>'
def p3(hexc, a=1):
    h = hexc.lstrip('#'); r, g, b = (int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
    return f"srgb:{r:.5f},{g:.5f},{b:.5f},{a:.5f}"
def bundle(name, fill, groups):
    d = os.path.join(OUT, f"{name}.icon"); os.makedirs(os.path.join(d, "Assets"), exist_ok=True)
    gs = []
    for g in groups:
        layers = []
        for lname, content in g["layers"]:
            open(os.path.join(d, "Assets", f"{lname}.svg"), "w").write(content)
            layers.append({"image-name": f"{lname}.svg", "name": lname, "glass": g.get("glass", True)})
        gs.append({"layers": layers, "shadow": {"kind": g.get("shadow", "neutral"), "opacity": 0.5},
                   "translucency": {"enabled": g.get("translucent", True), "value": g.get("tv", 0.4)}})
    icon = {"fill": fill, "groups": gs, "supported-platforms": {"circles": ["watchOS"], "squares": "shared"}}
    json.dump(icon, open(os.path.join(d, "icon.json"), "w"), indent=2)

def leaves(cx, cy, s):
    # Tomato calyx seen from slightly above: five lens-shaped leaves (squashed for perspective) and a stem
    L, parts = s * .3, []
    for k in range(5):
        a = math.radians(-90 + 36 + 72 * k)
        tx, ty = cx + math.cos(a) * L, cy + math.sin(a) * L
        nx, ny = -math.sin(a) * L * .3, math.cos(a) * L * .3
        mx, my = (cx + tx) / 2, (cy + ty) / 2
        parts.append(f"M{cx:.1f},{cy:.1f} Q{mx+nx:.1f},{my+ny:.1f} {tx:.1f},{ty:.1f} Q{mx-nx:.1f},{my-ny:.1f} {cx:.1f},{cy:.1f} Z")
    calyx = f'<path d="{" ".join(parts)}" fill="{LEAF}" transform="translate(0 {cy*.5:.1f}) scale(1 .5)"/>'
    stem = f'<path d="M{cx-s*.022:.1f},{cy+4:.1f} C{cx-s*.02:.1f},{cy-s*.08:.1f} {cx+s*.01:.1f},{cy-s*.12:.1f} {cx+s*.05:.1f},{cy-s*.14:.1f}" fill="none" stroke="{LEAF}" stroke-width="{s*.045:.1f}" stroke-linecap="round"/>'
    return calyx + stem

# ---------- A: Dial — the app's kitchen dial rising from the bottom, green pointer
cx, cy, R = 512, 1180, 720
top = cy - R
def polar(r, deg):
    t = math.radians(deg - 90); return cx + r * math.cos(t), cy + r * math.sin(t)
ticks = []
for i in range(-9, 10):
    deg = i * 6.5; major = i % 3 == 0
    x1, y1 = polar(R - 14, deg); x2, y2 = polar(R - (110 if major else 64), deg)
    ticks.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{TOMATO if major else INK}" stroke-opacity="{1 if major else .55}" stroke-width="{22 if major else 14}" stroke-linecap="round"/>')
# remaining-time band from the pointer to the left (as in the app)
r1, r2 = R, R - 150
a0, a1 = -42, 0
(ox1, oy1), (ox2, oy2) = polar(r1, a0), polar(r1, a1)
(ix2, iy2), (ix1, iy1) = polar(r2, a1), polar(r2, a0)
band = f'<path d="M{ox1:.1f},{oy1:.1f} A{r1},{r1} 0 0 1 {ox2:.1f},{oy2:.1f} L{ix2:.1f},{iy2:.1f} A{r2},{r2} 0 0 0 {ix1:.1f},{iy1:.1f} Z" fill="{BAND}"/>'
disc = f'<circle cx="{cx}" cy="{cy}" r="{R}" fill="{CREAM}"/>'
ptr = f'<path d="M512,{top + 70} L452,{top - 40} L572,{top - 40} Z" fill="{LEAF}" stroke="{LEAF}" stroke-width="26" stroke-linejoin="round"/>'
bundle("A-dial", {"automatic-gradient": p3(TOMATO)}, [
    {"layers": [("pointer", svg(ptr))]},
    {"layers": [("face", svg(band + "".join(ticks)))], "translucent": False},
    {"layers": [("disc", svg(disc))], "translucent": False},
])

# ---------- B: Tomato — flat tomato timer on cream
body = f'<ellipse cx="512" cy="590" rx="372" ry="330" fill="{TOMATO}"/>'
dial = (f'<line x1="250" y1="600" x2="774" y2="600" stroke="{CREAM}" stroke-width="26" stroke-linecap="round"/>' +
        "".join(f'<line x1="{x}" y1="520" x2="{x}" y2="555" stroke="{CREAM}" stroke-width="22" stroke-linecap="round"/>' for x in range(320, 720, 64)) +
        f'<path d="M512,650 L552,722 L472,722 Z" fill="{CREAM}" stroke="{CREAM}" stroke-width="14" stroke-linejoin="round"/>')
bundle("B-tomato", {"solid": p3(CREAM)}, [
    {"layers": [("leaves", svg(leaves(512, 285, 1024 * .9)))]},
    {"layers": [("dial", svg(dial))]},
    {"layers": [("body", svg(body))], "translucent": False},
])

# ---------- C: Band — tomato field, cream timer band with ticks, leaf crown
bandC = f'<rect x="-40" y="470" width="1104" height="210" rx="0" fill="{CREAM}"/>'
ticksC = "".join(f'<line x1="{x}" y1="{500}" x2="{x}" y2="{560 if (x // 80) % 2 else 590}" stroke="{TOMATO}" stroke-width="20" stroke-linecap="round"/>' for x in range(32, 1024, 80))
ptrC = f'<path d="M512,700 L560,790 L464,790 Z" fill="{INK}" stroke="{INK}" stroke-width="18" stroke-linejoin="round"/>'
bundle("C-band", {"automatic-gradient": p3(TOMATO)}, [
    {"layers": [("leaves", svg(leaves(512, 290, 1024 * .9)))]},
    {"layers": [("pointer", svg(ptrC)), ("ticks", svg(ticksC))]},
    {"layers": [("band", svg(bandC))], "translucent": False},
])
print("ok")
