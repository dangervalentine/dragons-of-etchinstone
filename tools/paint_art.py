"""Paints the coloured creature art for feature 008 with FLUX through ComfyUI, from
art/PAINTED_PROMPTS.txt: each creature's SUBJECT, EMANATION and the shared STYLE make
its prompt, its START is the silhouette it is painted over, and the SHARED STYLE
REFERENCES steer every creature's look through FLUX Redux. Images go to
build/art/painted/, one per creature and seed, for review.

Each image starts from the START drawn flat mid-grey on light grey, at --denoise
(0.88): the silhouette holds the pose and outline, and the prompt paints the rest. A
START is a silhouette from art/creatures/ (.svg), or a black-on-white .png, such as a
silhouette with a part painted out.

ComfyUI must be running with FLUX and the Redux models (tools/setup_comfyui.sh or .ps1,
then hf auth login for the gated Redux model). Run this with ComfyUI's Python, which
has resvg-py and pillow. Point --server at another computer's ComfyUI to share the work.

Run:
  python3 tools/paint_art.py list
  python3 tools/paint_art.py prompt lion-archer
  python3 tools/paint_art.py paint [names...] [--seed 81] [--count 4] [--q8]
  python3 tools/paint_art.py paint all --server http://other-pc:8188 --q8
  python3 tools/paint_art.py paint crane-monk --seed 101 --tag vector --q8

paint queues every image first, so they all show in ComfyUI's queue, then saves each
as it finishes. An image already in build/art/painted/ is skipped.
"""
import argparse
import json
import os
import random
import re
import sys
import time
import urllib.parse

sys.path.insert(0, os.path.dirname(__file__))
import generate_art as ga

ROOT = ga.ROOT
DOC = os.path.join(ROOT, "art", "PAINTED_PROMPTS.txt")
OUT = os.path.join(ROOT, "build", "art", "painted")
STARTS = os.path.join(OUT, "starts")
DENOISE = 0.88
# Redux strength for each shared reference. Above about 0.05 it copies the
# references' colours and designs rather than their style (iteration 2b).
STYLE_STRENGTH = 0.05
# The grey the START is drawn in, and the ground around it: flat shapes for FLUX to
# paint over, light enough for colour to come in.
FIGURE_GREY = 128
GROUND_GREY = 216


# The doc

def squash(text):
    return " ".join(text.split())


def between(text, start, end):
    i = text.index(start) + len(start)
    return squash(text[i:text.index(end, i)])


def read_doc():
    text = open(DOC, encoding="utf-8").read()
    shared = text[text.index("SHARED STYLE REFERENCES"):text.index("\nSTYLE (")]
    refs = [os.path.join(ROOT, p) for p in re.findall(r"^(art/\S+\.png)", shared, re.M)]
    head = re.search(r"^STYLE \(.*\n-+\n", text, re.M)
    style = squash(text[head.end():text.index("\nEMANATION (")])
    creatures = {}
    for m in re.finditer(r"^\d+\. .*?\(([a-z-]+) ·.*?(?=^\d+\. |\Z)", text, re.M | re.S):
        name, section = m.group(1), m.group(0)
        subject = between(section, "SUBJECT:", "EMANATION:")
        emanation = between(section, "EMANATION:", "YOUR VISION:")
        creatures[name] = {
            "prompt": " ".join([subject, emanation, style]),
            "start": re.search(r"^START: (\S+)", section, re.M).group(1),
        }
    return refs, creatures


# Starting images

def grey_start(name, start):
    """The START drawn flat grey on light grey, SIZE pixels square, as a file."""
    from PIL import Image
    os.makedirs(STARTS, exist_ok=True)
    bw = os.path.join(STARTS, name + "-bw.png")
    if start.endswith(".svg"):
        ga.render_start(os.path.basename(start)[:-4], bw)
    else:
        Image.open(os.path.join(ROOT, start)).convert("L").save(bw)
    span = GROUND_GREY - FIGURE_GREY
    dest = os.path.join(STARTS, name + ".png")
    (Image.open(bw).convert("L").point(lambda v: FIGURE_GREY + v / 255 * span)
     .convert("RGB").save(dest))
    return dest


# ComfyUI

def graph(prompt, start, refs, seed, denoise, strength, prefix):
    """Image to image from start, its positive conditioning passed through Redux once
    for each reference; plain image to image when there are none."""
    g = ga.image_to_image(prompt, start, seed, denoise, prefix)
    if not refs:
        return g
    positive = ["guide", 0]
    g["vision"] = {"class_type": "CLIPVisionLoader", "inputs": {"clip_name": ga.STYLE_VISION}}
    g["redux"] = {"class_type": "StyleModelLoader", "inputs": {"style_model_name": ga.STYLE_MODEL}}
    for i, ref in enumerate(refs):
        g["ref%d" % i] = {"class_type": "LoadImage", "inputs": {"image": ref}}
        g["seen%d" % i] = {"class_type": "CLIPVisionEncode", "inputs": {
            "clip_vision": ["vision", 0], "image": ["ref%d" % i, 0], "crop": "center"}}
        g["styled%d" % i] = {"class_type": "StyleModelApply", "inputs": {
            "conditioning": positive, "style_model": ["redux", 0],
            "clip_vision_output": ["seen%d" % i, 0], "strength": strength,
            "strength_type": ga.STYLE_TYPE}}
        positive = ["styled%d" % i, 0]
    g["sample"]["inputs"]["positive"] = positive
    return g


def queue(g):
    r = json.loads(ga.call("/prompt", json.dumps({"prompt": g}).encode(),
                           {"Content-Type": "application/json"}))
    return r["prompt_id"]


def fetch(pid, dest):
    """Waits for a queued graph and saves its image to dest."""
    while True:
        h = json.loads(ga.call("/history/" + pid))
        if pid in h:
            break
        time.sleep(3)
    entry = h[pid]
    if entry.get("status", {}).get("status_str") == "error":
        print("failed", os.path.relpath(dest, ROOT),
              json.dumps(entry["status"].get("messages", []))[:2000])
        return
    img = next(o["images"][0] for o in entry["outputs"].values() if "images" in o)
    q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"],
                                "type": img["type"]})
    with open(dest, "wb") as f:
        f.write(ga.call("/view?" + q))
    print("wrote", os.path.relpath(dest, ROOT), flush=True)


# Commands

def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("command", choices=["list", "prompt", "paint"])
    p.add_argument("names", nargs="*", help="creatures from the doc, e.g. lion-archer, or all")
    p.add_argument("--seed", type=int, help="the first seed; random if left out")
    p.add_argument("--count", type=int, default=4, help="how many seeds to try; %(default)s")
    p.add_argument("--denoise", type=float, default=DENOISE,
                   help="how far to stray from the START, 0 to 1; %(default)s")
    p.add_argument("--style-strength", type=float, default=STYLE_STRENGTH,
                   help="Redux strength for each shared reference; %(default)s")
    p.add_argument("--server", default=ga.SERVER, help="the ComfyUI to use; %(default)s")
    p.add_argument("--q8", action="store_true", help="use the Q8 models")
    p.add_argument("--tag", default="",
                   help="added to each file name, to rerun the same seeds after a prompt change")
    a = p.parse_args()
    ga.SERVER = a.server.rstrip("/")
    ga.models = ga.MODELS["q8" if a.q8 else "q4"]
    refs, creatures = read_doc()
    if a.command == "list":
        for name, c in creatures.items():
            print("%-16s start %s" % (name, c["start"]))
        print("shared references:", ", ".join(os.path.relpath(r, ROOT) for r in refs))
        return
    names = list(creatures) if a.names in ([], ["all"]) else a.names
    for name in names:
        if name not in creatures:
            sys.exit("%s isn't in %s; see 'list'" % (name, os.path.relpath(DOC, ROOT)))
    if a.command == "prompt":
        for name in names:
            print("%s:\n%s\n" % (name, creatures[name]["prompt"]))
        return
    os.makedirs(OUT, exist_ok=True)
    seed = a.seed if a.seed is not None else random.randrange(1 << 32)
    uploaded = None
    jobs = []
    for name in names:
        c = creatures[name]
        start = None
        for s in range(seed, seed + a.count):
            tag = "-" + a.tag if a.tag else ""
            dest = os.path.join(OUT, "%s-%d%s.png" % (name, s, tag))
            if os.path.exists(dest):
                print("have", os.path.relpath(dest, ROOT))
                continue
            uploaded = uploaded or [ga.upload(r) for r in refs]
            start = start or ga.upload(grey_start(name, c["start"]))
            g = graph(c["prompt"], start, uploaded, s, a.denoise, a.style_strength,
                      "etch008/%s-%d%s" % (name, s, tag))
            jobs.append((queue(g), dest))
            print("queued", name, s, flush=True)
    for pid, dest in jobs:
        fetch(pid, dest)


if __name__ == "__main__":
    main()
