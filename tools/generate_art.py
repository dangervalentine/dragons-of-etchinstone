"""Generates creature art with FLUX through a local ComfyUI, using the subject lines
and style block in art/STYLE_PROMPT.md. Images are written to build/art/, black on
white, for review and then tools/vectorize_art.py.

ComfyUI must be running (cd ~/ComfyUI && .venv/bin/python main.py) with the
ComfyUI-GGUF custom node and the models named below: FLUX and FLUX Fill in
models/unet, CLIP and T5 in models/text_encoders, ae.safetensors in models/vae.
tools/setup_comfyui.sh (or .ps1 on Windows) sets all that up, and installs what
restyle and start need (resvg-py, plus pillow, numpy and potracer for
vectorize_art.py) into ComfyUI's Python, so run this script with that Python. Point
--server at another computer's ComfyUI to share the work.

generate draws from the prompt alone. restyle starts from the current silhouette in
art/creatures/ and redraws it in the prompt's style, keeping its pose and outline;
--denoise sets how far it may stray (0 keeps it, 1 ignores it), and takes several
values to compare them in one run. start writes that
starting image to build/art/starts/ to paint on, for instance to block in a lightning
tail in black, and restyle then uses the painted one.

Run:
  python3 tools/generate_art.py list
  python3 tools/generate_art.py prompt tortoise
  python3 tools/generate_art.py generate tortoise vulture [--seed 7] [--count 4]
  python3 tools/generate_art.py restyle tortoise vulture [--denoise 0.85 0.9 0.95] [--count 4]
  python3 tools/generate_art.py start vulture
  python3 tools/generate_art.py generate all --server http://other-pc:8188 --q8
  python3 tools/generate_art.py body tortoise --image build/art/tortoise-7.png \\
      --mask build/art/tortoise-mask.png [--fill "the front of the shell, solid"]
"""
import argparse
import json
import os
import random
import re
import sys
import time
import urllib.parse
import urllib.request
import uuid

ROOT = os.path.join(os.path.dirname(__file__), "..")
DOC = os.path.join(ROOT, "art", "STYLE_PROMPT.md")
OUT = os.path.join(ROOT, "build", "art")
STARTS = os.path.join(OUT, "starts")
ART = os.path.join(ROOT, "art", "creatures")
SERVER = "http://127.0.0.1:8188"

# Q4_K_S builds: about 7 GB each, so a 24 GB Mac doesn't swap. The Q8 builds are
# sharper but need the memory to themselves.
# --q8 picks the Q8 builds on a computer with the memory for them.
MODELS = {
    "q4": {"unet": "flux1-dev-Q4_K_S.gguf", "fill": "flux1-fill-dev-Q4_K_S.gguf",
           "t5": "t5-v1_1-xxl-encoder-Q5_K_M.gguf"},
    "q8": {"unet": "flux1-dev-Q8_0.gguf", "fill": "flux1-fill-dev-Q8_0.gguf",
           "t5": "t5-v1_1-xxl-encoder-Q8_0.gguf"},
}
models = MODELS["q4"]

SIZE = 1024
STEPS = 25
# FLUX's own guidance: low keeps it looser and more varied, high follows the prompt
# more literally. Fill is trained to work at 30.
GUIDANCE = 3.5
FILL_GUIDANCE = 30.0
# How far restyle may stray from the starting silhouette by default. At 0.7 the first
# tortoise and vulture came back almost unchanged: a flat black start holds FLUX
# tightly, so the useful range is likely 0.85 to 0.95.
DENOISE = 0.9
# The starting silhouette is drawn this many art units in from each edge, the margin
# the style block asks for; the art fills its 512-unit square edge to edge.
START_MARGIN = 44


# The doc

def quoted_after(text, heading):
    """The > quoted paragraph that follows a line containing heading."""
    start = text.index(heading)
    lines = []
    for line in text[start:].splitlines()[1:]:
        line = line.strip()
        if line.startswith(">"):
            lines.append(line[1:].strip())
        elif lines:
            break
    return " ".join(lines)


def read_doc():
    text = open(DOC, encoding="utf-8").read()
    style = quoted_after(text, "## Style block")
    journey = quoted_after(text, "For **journey scenes**")
    moving = quoted_after(text, "For **images with a moving part**")
    body = quoted_after(text, "3. **Make the body layer by inpainting**")
    subjects = {}
    for row in re.findall(r"^\| ([a-z-]+) \| (.+?) \| (.+?) \| (.+?) \|$", text, re.M):
        name, title, subject, part = row
        if name == "File":
            continue
        subjects[name] = {
            "title": title,
            "subject": subject,
            "journey": "*(journey)*" in title,
            # "Lower jaw · hinge 18° open, ... · the underside of the skull, solid."
            "part": part.split(" · ")[0] if part != "—" else "",
            "fill": part.split(" · ")[2] if part.count(" · ") >= 2 else "",
        }
    return {"style": style, "journey": journey, "moving": moving, "body": body,
            "subjects": subjects}


def prompt_for(doc, name):
    s = doc["subjects"][name]
    parts = [s["subject"], doc["style"]]
    if s["journey"]:
        parts.append(doc["journey"])
    if s["part"]:
        parts.append(doc["moving"].replace("[MOVING PART]", s["part"].lower()))
    return " ".join(parts)


# ComfyUI

def call(path, data=None, headers=None):
    req = urllib.request.Request(SERVER + path, data=data, headers=headers or {})
    try:
        with urllib.request.urlopen(req) as r:
            return r.read()
    except urllib.error.URLError as e:
        sys.exit("ComfyUI isn't answering at %s (%s). Start it first." % (SERVER, e))


def upload(path):
    """Uploads an image to ComfyUI's input folder and returns its name there."""
    boundary = uuid.uuid4().hex
    name = os.path.basename(path)
    body = (("--%s\r\nContent-Disposition: form-data; name=\"image\"; filename=\"%s\"\r\n"
             "Content-Type: image/png\r\n\r\n" % (boundary, name)).encode()
            + open(path, "rb").read()
            + ("\r\n--%s\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue"
               "\r\n--%s--\r\n" % (boundary, boundary)).encode())
    r = call("/upload/image", body, {"Content-Type": "multipart/form-data; boundary=" + boundary})
    return json.loads(r)["name"]


def run(graph, dest):
    """Queues a graph, waits for it and saves its one output image to dest."""
    r = json.loads(call("/prompt", json.dumps({"prompt": graph}).encode(),
                        {"Content-Type": "application/json"}))
    pid = r["prompt_id"]
    while True:
        time.sleep(1.5)
        h = json.loads(call("/history/" + pid))
        if pid in h:
            break
    entry = h[pid]
    if entry.get("status", {}).get("status_str") == "error":
        sys.exit("ComfyUI failed: %s" % json.dumps(entry["status"].get("messages", []))[:2000])
    img = next(o["images"][0] for o in entry["outputs"].values() if "images" in o)
    q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"],
                                "type": img["type"]})
    with open(dest, "wb") as f:
        f.write(call("/view?" + q))
    print("wrote", os.path.relpath(dest, ROOT))


def loaders(unet):
    return {
        "unet": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": unet}},
        "clip": {"class_type": "DualCLIPLoaderGGUF", "inputs": {
            "clip_name1": "clip_l.safetensors",
            "clip_name2": models["t5"], "type": "flux"}},
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": "ae.safetensors"}},
    }


def sampler(model, positive, negative, latent, seed, denoise=1.0):
    return {"class_type": "KSampler", "inputs": {
        "model": model, "positive": positive, "negative": negative,
        "latent_image": latent, "seed": seed, "steps": STEPS, "cfg": 1.0,
        "sampler_name": "euler", "scheduler": "simple", "denoise": denoise}}


def text_to_image(prompt, seed, prefix):
    g = loaders(models["unet"])
    g.update({
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["clip", 0], "text": prompt}},
        "guide": {"class_type": "FluxGuidance", "inputs": {"conditioning": ["pos", 0],
                                                          "guidance": GUIDANCE}},
        # FLUX dev takes no negative prompt; an empty one fills the slot.
        "neg": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["clip", 0], "text": ""}},
        "latent": {"class_type": "EmptySD3LatentImage", "inputs": {
            "width": SIZE, "height": SIZE, "batch_size": 1}},
        "sample": sampler(["unet", 0], ["guide", 0], ["neg", 0], ["latent", 0], seed),
        "decode": {"class_type": "VAEDecode", "inputs": {"samples": ["sample", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["decode", 0],
                                                       "filename_prefix": prefix}},
    })
    return g


def image_to_image(prompt, image, seed, denoise, prefix):
    g = loaders(models["unet"])
    g.update({
        "image": {"class_type": "LoadImage", "inputs": {"image": image}},
        "encode": {"class_type": "VAEEncode", "inputs": {"pixels": ["image", 0], "vae": ["vae", 0]}},
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["clip", 0], "text": prompt}},
        "guide": {"class_type": "FluxGuidance", "inputs": {"conditioning": ["pos", 0],
                                                          "guidance": GUIDANCE}},
        "neg": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["clip", 0], "text": ""}},
        "sample": sampler(["unet", 0], ["guide", 0], ["neg", 0], ["encode", 0], seed, denoise),
        "decode": {"class_type": "VAEDecode", "inputs": {"samples": ["sample", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["decode", 0],
                                                       "filename_prefix": prefix}},
    })
    return g


def inpaint(prompt, image, mask, seed, prefix):
    g = loaders(models["fill"])
    g.update({
        "image": {"class_type": "LoadImage", "inputs": {"image": image}},
        # White over the part in the mask: the red channel of a grey image will do.
        "mask": {"class_type": "LoadImageMask", "inputs": {"image": mask, "channel": "red"}},
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["clip", 0], "text": prompt}},
        "guide": {"class_type": "FluxGuidance", "inputs": {"conditioning": ["pos", 0],
                                                          "guidance": FILL_GUIDANCE}},
        "neg": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["clip", 0], "text": ""}},
        "cond": {"class_type": "InpaintModelConditioning", "inputs": {
            "positive": ["guide", 0], "negative": ["neg", 0], "vae": ["vae", 0],
            "pixels": ["image", 0], "mask": ["mask", 0], "noise_mask": True}},
        "diff": {"class_type": "DifferentialDiffusion", "inputs": {"model": ["unet", 0]}},
        "sample": sampler(["diff", 0], ["cond", 0], ["cond", 1], ["cond", 2], seed),
        "decode": {"class_type": "VAEDecode", "inputs": {"samples": ["sample", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["decode", 0],
                                                       "filename_prefix": prefix}},
    })
    return g


# Starting images

def render_start(name, dest):
    """Draws art/creatures/<name>.svg black on white, SIZE pixels square, with the
    style block's margin."""
    try:
        import resvg_py
    except ImportError:
        sys.exit("restyle and start need resvg-py: run this with ComfyUI's Python, "
                 "or pip install resvg-py")
    svg = open(os.path.join(ART, name + ".svg"), encoding="utf-8").read()
    svg = svg.replace('fill="#fff"', 'fill="#000"')
    m = START_MARGIN
    svg = re.sub(r'viewBox="[^"]*"', 'viewBox="%d %d %d %d"' % (-m, -m, 512 + 2 * m, 512 + 2 * m), svg)
    png = resvg_py.svg_to_bytes(svg_string=svg, width=SIZE, height=SIZE, background="#ffffff")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "wb") as f:
        f.write(bytes(png))


def start_for(name):
    """The painted starting image if there is one, else a fresh one from the art."""
    painted = os.path.join(STARTS, name + ".png")
    if os.path.exists(painted):
        print("starting from", os.path.relpath(painted, ROOT))
        return painted
    fresh = os.path.join(OUT, ".start-%s.png" % name)
    render_start(name, fresh)
    return fresh


# Commands

def main():
    global SERVER, models
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("command", choices=["list", "prompt", "generate", "restyle", "start", "body"])
    p.add_argument("names", nargs="*", help="file names from the doc's tables, e.g. tortoise, "
                   "or all")
    p.add_argument("--seed", type=int, help="the first seed; random if left out")
    p.add_argument("--count", type=int, default=1, help="how many seeds to try, one after another")
    p.add_argument("--denoise", type=float, nargs="+", default=[DENOISE],
                   help="restyle: how far to stray from the start, 0 to 1, one value or "
                   "several to compare; %(default)s by default")
    p.add_argument("--image", help="body: the approved whole image")
    p.add_argument("--mask", help="body: white over the moving part")
    p.add_argument("--fill", help="body: what fills the gap, if not the doc's")
    p.add_argument("--server", default=SERVER, help="the ComfyUI to use; %(default)s by default")
    p.add_argument("--q8", action="store_true", help="use the Q8 models")
    a = p.parse_args()
    SERVER = a.server.rstrip("/")
    models = MODELS["q8" if a.q8 else "q4"]
    doc = read_doc()
    if a.command == "list":
        for name, s in doc["subjects"].items():
            print("%-20s %s%s" % (name, s["title"], "  [part: %s]" % s["part"] if s["part"] else ""))
        return
    names = list(doc["subjects"]) if a.names == ["all"] else a.names
    if not names:
        sys.exit("name at least one subject; see 'list'")
    for name in names:
        if name not in doc["subjects"]:
            sys.exit("%s isn't in %s; see 'list'" % (name, os.path.relpath(DOC)))
    if a.command not in ("generate", "restyle", "start") and len(names) > 1:
        sys.exit("%s takes one name" % a.command)
    os.makedirs(OUT, exist_ok=True)
    seed = a.seed if a.seed is not None else random.randrange(1 << 32)
    if a.command == "prompt":
        print(prompt_for(doc, names[0]))
    elif a.command == "generate":
        for name in names:
            prompt = prompt_for(doc, name)
            for s in range(seed, seed + a.count):
                dest = os.path.join(OUT, "%s-%d.png" % (name, s))
                if os.path.exists(dest):
                    print("have", os.path.relpath(dest, ROOT))
                    continue
                run(text_to_image(prompt, s, "etch/" + name), dest)
    elif a.command == "start":
        for name in names:
            dest = os.path.join(STARTS, name + ".png")
            if os.path.exists(dest):
                print("have", os.path.relpath(dest, ROOT), "(delete it to start again)")
                continue
            render_start(name, dest)
            print("wrote", os.path.relpath(dest, ROOT), "- paint on it in black and white")
    elif a.command == "restyle":
        for name in names:
            prompt = prompt_for(doc, name)
            image = None
            for d in a.denoise:
                for s in range(seed, seed + a.count):
                    dest = os.path.join(OUT, "%s-restyle%02d-%d.png" % (name, round(d * 100), s))
                    if os.path.exists(dest):
                        print("have", os.path.relpath(dest, ROOT))
                        continue
                    image = image or upload(start_for(name))
                    run(image_to_image(prompt, image, s, d, "etch/" + name), dest)
    elif a.command == "body":
        name = names[0]
        if not (a.image and a.mask):
            sys.exit("body needs --image and --mask")
        s = doc["subjects"][name]
        if not s["part"]:
            sys.exit("%s has no moving part in the doc" % name)
        prompt = (doc["body"].replace("[MOVING PART]", s["part"].lower())
                  .replace("[WHAT FILLS THE GAP]", a.fill or s["fill"].rstrip(".")))
        run(inpaint(prompt, upload(a.image), upload(a.mask), seed, "etch/" + name + "-body"),
            os.path.join(OUT, "%s-body-%d.png" % (name, seed)))


if __name__ == "__main__":
    main()
