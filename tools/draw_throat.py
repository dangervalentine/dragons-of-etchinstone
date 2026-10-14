"""Draws the body layer of a dragon whose lower jaw moves: the approved whole image
with the jaw taken out and a solid throat behind the corner of the mouth, so that
when the jaw drops the mouth gapes and nothing shows through behind it.

The throat's new outline is one smooth curve, from a point on the upper jaw about a
third of the way from the hinge to the front of the mouth, bulging down and back
into the neck. Inside the jaw mask the result is black only where the whole image
is black as well, so body + jaw is exactly the whole image when the mouth is shut:
the throat is solid only where the whole image is black inside its outline, and
BELOW starts that outline under the lower teeth, clear of the gaps between them.

Why not FLUX Fill (tools/generate_art.py body)? On all four dragons, with several
seeds and a plainer fill text, it redrew a second toothed lower jaw under the upper
teeth; filling only the throat, with the jaw already painted out, cut holes in the
head instead. The throat is mostly hidden behind the jaw, so a drawn curve is enough.

The constants below are in the 1024-pixel images, read off a grid render of each
build/art/prime/<name>.png (art/STYLE_PROMPT.md, "Making the two layers"):
  H     the hinge, the back corner of the mouth; Art.PARTS pivot is H / 2
  F     the front end of the gap between the teeth
  K     where the jaw mask's top edge ends, about 15 px behind the hinge
  Q, C  the throat curve's control point and its end, on the neck's underside
  back  points closing the throat behind the hinge, inside the head

The mask is build/art/<name>-mask.png: white over the lower jaw, its teeth and the
jaw underside, running past the hinge; the same mask cuts the part layer.

Needs: pip install pillow numpy
Run: python3 tools/draw_throat.py grimroch
     python3 tools/vectorize_art.py build/art/grimroch-body-hand.png art/creatures/grimroch-base.svg
     python3 tools/vectorize_art.py build/art/prime/grimroch.png --mask build/art/grimroch-mask.png \\
         art/creatures/grimroch-part.svg
"""
import argparse

import numpy as np
from PIL import Image, ImageDraw

DRAGONS = {
    "grimroch": {"H": (806, 382), "F": (897, 447), "K": (794, 373), "Q": (842, 447),
                 "C": (806, 450), "back": [(790, 449), (790, 370)]},
    "helsang": {"H": (798, 316), "F": (857, 358), "K": (786, 307), "Q": (803, 368),
                "C": (766, 339), "back": [(757, 333), (770, 300)]},
    "rodving": {"H": (757, 200), "F": (848, 212), "K": (742, 198), "Q": (790, 240),
                "C": (745, 240), "back": [(735, 240), (735, 195)]},
    "vuurhast": {"H": (715, 193), "F": (825, 253), "K": (702, 186), "Q": (748, 246),
                 "C": (703, 238), "back": [(695, 238), (695, 185)]},
}
SIZE = 1024
# How far along the mouth, hinge to front, the throat leaves the upper jaw.
ALONG = 0.35
# How far below the gap it leaves it: under the roots of the lower teeth, so none
# of them stays behind on the body.
BELOW = 10.0
# Drawn this many times larger, then scaled down, for a smooth edge.
SUPERSAMPLE = 4


def throat(rig):
    """The throat's outline, a polygon in image pixels."""
    h, f = np.array(rig["H"], float), np.array(rig["F"], float)
    d = f - h
    length = np.hypot(*d)
    d /= length
    down = np.array([-d[1], d[0]])
    a = h + ALONG * length * d + BELOW * down
    q, c = np.array(rig["Q"], float), np.array(rig["C"], float)
    t = np.linspace(0, 1, 40)[:, None]
    curve = (1 - t) ** 2 * a + 2 * (1 - t) * t * q + t ** 2 * c
    return [tuple(rig["K"]), tuple(h), *map(tuple, curve), *rig["back"]]


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("name", choices=sorted(DRAGONS))
    parser.add_argument("--image", help="the approved whole image (build/art/prime/<name>.png)")
    parser.add_argument("--mask", help="white over the jaw (build/art/<name>-mask.png)")
    parser.add_argument("--out", help="the body image to write (build/art/<name>-body-hand.png)")
    a = parser.parse_args()
    image = a.image or "build/art/prime/%s.png" % a.name
    mask = a.mask or "build/art/%s-mask.png" % a.name
    out = a.out or "build/art/%s-body-hand.png" % a.name

    s = SUPERSAMPLE
    big = Image.new("L", (SIZE * s, SIZE * s), 255)
    ImageDraw.Draw(big).polygon([(x * s, y * s) for x, y in throat(DRAGONS[a.name])], fill=0)
    fill = np.asarray(big.resize((SIZE, SIZE), Image.LANCZOS)).astype(float)
    whole = np.asarray(Image.open(image).convert("L")).astype(float)
    jaw = np.asarray(Image.open(mask).convert("L")) > 127
    # Black only where the whole is black, so body + jaw is exactly the whole.
    body = np.where(jaw, np.maximum(fill, whole), whole)
    Image.fromarray(body.astype(np.uint8)).convert("RGB").save(out)
    print("wrote", out)


if __name__ == "__main__":
    main()
