"""Puts hand-finished silhouettes on one common canvas, ready for vectorize_art.py and
for training: 1024 x 1024, pure black on white, every subject scaled to fill the same
box, centred across and standing on the same bottom line.

The touch-ups (art/source/touch-up/<name>.png) are black on transparent, cropped tight
and of any size. Their soft edges are kept through the resize and only then cut at the
midpoint, so an image scaled up comes out with smooth edges, not stair steps.

Needs: pip install pillow numpy
Run: python3 tools/frame_art.py                 every image in art/source/touch-up/
     python3 tools/frame_art.py naga twin-ogre  just these
     python3 tools/frame_art.py peaks=path/to/peaks_00004_.png
                                                any image, black on white or on
                                                transparent, framed as art/source/peaks.png
"""
import argparse
import glob
import os

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art", "source", "touch-up")
OUT = os.path.join(ROOT, "art", "source")
SIZE = 1024
# The box every subject is scaled to fill, as the dragons fill theirs: an even margin
# at the sides and top, and the feet on a line near the bottom (the "breathe" motion
# scales about a point 95% of the way down).
LEFT, RIGHT, TOP, FLOOR = 64, 960, 48, 980


def coverage(path):
    """How much ink each pixel holds, 0 to 1: dark and opaque is ink."""
    rgba = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255
    return rgba[:, :, 3] * (1 - rgba[:, :, :3].mean(axis=2))


def frame(path):
    ink = coverage(path)
    ys, xs = np.nonzero(ink > 0.5)
    ink = ink[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    h, w = ink.shape
    k = min((RIGHT - LEFT) / w, (FLOOR - TOP) / h)
    size = (round(w * k), round(h * k))
    layer = Image.fromarray((ink * 255).astype(np.uint8)).resize(size, Image.LANCZOS)
    if k > 1:
        # Soften the enlarged pixels before the cut, in proportion to the enlargement.
        layer = layer.filter(ImageFilter.GaussianBlur(0.5 * k))
    canvas = Image.new("L", (SIZE, SIZE), 0)
    canvas.paste(layer, ((SIZE - size[0]) // 2, FLOOR - size[1]))
    black = np.asarray(canvas) >= 128
    return Image.fromarray(np.where(black, 0, 255).astype(np.uint8))


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("names", nargs="*",
                   help="file names without .png, or name=image; all touch-ups when left out")
    a = p.parse_args()
    jobs = []
    for n in a.names or [os.path.basename(f)[:-4] for f in sorted(glob.glob(os.path.join(SRC, "*.png")))]:
        name, _, path = n.partition("=")
        jobs.append((name, path or os.path.join(SRC, name + ".png")))
    for name, path in jobs:
        dest = os.path.join(OUT, name + ".png")
        frame(path).save(dest)
        print("wrote", os.path.relpath(dest, ROOT))


if __name__ == "__main__":
    main()
