"""Construit les maquettes DarImmo à partir de src/ :
   - maquettes_darimmo.html        (page web autonome, à ouvrir dans Chrome)
   - figma-plugin/manifest.json + code.js  (plugin Figma qui dessine les écrans)
Usage :  python build.py   [dossier_copie_artifact]
"""
import base64, io, json, os, sys
from PIL import Image

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, "src")
IMG = os.path.join(ROOT, "img_src")

PHOTOS = {
    "villa1": "1600596542815-ffad4c1539a9", "villa2": "1580587771525-78b9dba3b914",
    "villa3": "1600585154526-990dced4db0d", "salon1": "1560448204-e02f11c3d0e2",
    "salon2": "1522708323590-d24dbb6b0267", "salon3": "1493809842364-78817add7ffb",
    "salon4": "1502672260266-1c1ef2d93688", "chambre": "1505691938895-1758d7feb511",
    "terrain": "1500382017468-9049fed747ef", "local": "1441986300917-64674bd600d8",
}
AVATARS = {"avatarF": "1494790108377-be9c29b29330", "avatarM": "1507003211169-0a1dd7228f2d",
           "avatarF2": "1534528741775-53994a69daeb"}


def encode(path, width=None, square=None, quality=70):
    im = Image.open(path).convert("RGB")
    if square:
        s = min(im.size)
        left, top = (im.width - s) // 2, max(0, (im.height - s) // 3)
        im = im.crop((left, top, left + s, top + s)).resize((square, square), Image.LANCZOS)
    elif width and im.width > width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=quality, optimize=True, progressive=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def images_js():
    out = {}
    for k, pid in PHOTOS.items():
        out[k] = encode(os.path.join(IMG, pid + ".jpg"), width=640 if k != "villa3" else 600)
    for k, pid in AVATARS.items():
        out[k] = encode(os.path.join(IMG, pid + ".jpg"), square=192, quality=75)
    return "var IMAGES = " + json.dumps(out) + ";\n"


def read(name):
    with open(os.path.join(SRC, name), encoding="utf-8") as f:
        return f.read()


def tokens_css(spec):
    # extrait TOKENS de spec.js (format simple : nom: ['#clair', '#sombre'])
    import re
    pairs = re.findall(r"^\s+(\w+):\s+\['(#[0-9A-Fa-f]+)',\s*'(#[0-9A-Fa-f]+)'\]", spec, re.M)
    light = " ".join(f"--t-{n}: {a};" for n, a, b in pairs)
    dark = " ".join(f"--t-{n}: {b};" for n, a, b in pairs)
    return light, dark, len(pairs)


def main():
    imgs = images_js()
    spec, rhtml, rfig, page = read("spec.js"), read("render_html.js"), read("render_figma.js"), read("page.html")
    light, dark, n = tokens_css(spec)
    html = (page.replace("/*__TOKENS_LIGHT__*/", light).replace("/*__TOKENS_DARK__*/", dark)
            .replace("/*__BUNDLE__*/", imgs + spec + "\n" + rhtml))

    # 1) page autonome (avec squelette HTML, pour l'ouvrir en local)
    local = ('<!doctype html>\n<html lang="fr">\n<head>\n<meta charset="utf-8">\n'
             '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
             '</head>\n<body>\n' + html + '\n</body>\n</html>\n')
    with open(os.path.join(ROOT, "maquettes_darimmo.html"), "w", encoding="utf-8") as f:
        f.write(local)

    # 2) plugin Figma
    plug = os.path.join(ROOT, "figma-plugin")
    os.makedirs(plug, exist_ok=True)
    manifest = {"name": "DarImmo Maquettes", "id": "darimmo-maquettes-v3", "api": "1.0.0", "main": "code.js",
                "editorType": ["figma"], "documentAccess": "dynamic-page",
                "networkAccess": {"allowedDomains": ["none"]}}
    with open(os.path.join(plug, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    with open(os.path.join(plug, "code.js"), "w", encoding="utf-8") as f:
        f.write("/* Généré par build.py — ne pas modifier à la main : modifiez src/spec.js puis relancez build.py */\n")
        f.write(imgs + spec + "\n" + rfig)

    # 3) copie pour publication (sans squelette)
    if len(sys.argv) > 1:
        with open(os.path.join(sys.argv[1], "maquettes_darimmo.html"), "w", encoding="utf-8") as f:
            f.write(html)
    print(f"OK · {n} couleurs · page {len(local)//1024} Ko · plugin {os.path.getsize(os.path.join(plug, 'code.js'))//1024} Ko")


if __name__ == "__main__":
    main()
