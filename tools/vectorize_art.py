"""Turns a generated black-on-white image into a creature SVG the game can tint: one
white shape on a transparent 512-unit square. The canvas is only scaled, never cropped
or re-centred, so a creature's body and moving part stay in register.

With --mask, only the shape under the mask's white area is kept: that is how a moving
part (a jaw, a wing) is cut from the whole image. See art/STYLE_PROMPT.md.

Needs: pip install pillow numpy potracer
Run: python3 tools/vectorize_art.py generated/tortoise.png art/creatures/tortoise.svg
     python3 tools/vectorize_art.py generated/tortoise.png --mask generated/tortoise-mask.png \
         art/creatures/tortoise-part.svg
"""
import argparse
import sys

import numpy as np
import potrace
from PIL import Image

SIZE = 512
# Pixels darker than this are the shape. Generators leave soft edges and faint grey
# noise; a midpoint keeps the outline where the eye puts it.
THRESHOLD = 128
# Specks smaller than this many pixels are noise, not detail.
TURD_SIZE = 8
# Generators like to stand a creature on a thin ground line: rows near the bottom
# that run much wider than the feet above them. Where nothing stands on it, it is
# cleared, if those stretches add up to GROUND_SPAN pixels; less is toes and claws.
# Measured on the first generated tortoises and vultures: ground lines 206 to 225,
# feet without one 97 at most.
GROUND_DEPTH = 30
GROUND_WIDER = 1.25
GROUND_SPAN = 150
# The line tapers at its ends; clear this far above its widest rows to catch them.
GROUND_TAPER = 6


def load_grey(src):
    """The image in grey levels, at 512 x 512."""
    img = Image.open(src)
    if img.mode in ("RGBA", "LA", "P"):
        img = img.convert("RGBA")
        img = Image.alpha_composite(Image.new("RGBA", img.size, "white"), img)
    img = img.convert("L")
    if img.width != img.height:
        sys.exit("%s is %dx%d; the art must be square" % (src, img.width, img.height))
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    return np.asarray(img)


def remove_ground(shape):
    """Clears a ground line from under the subject, keeping what is under its feet.
    Returns True if there was one."""
    rows = np.flatnonzero(shape.any(axis=1))
    bottom = rows[-1]
    if bottom - GROUND_DEPTH - 15 < 0:
        return False
    width = shape.sum(axis=1)
    # The feet: the rows just above where a ground line would be.
    feet = np.median(width[bottom - GROUND_DEPTH - 15:bottom - GROUND_DEPTH])
    wide = [y for y in range(bottom - GROUND_DEPTH, bottom + 1) if width[y] > feet * GROUND_WIDER]
    if not wide:
        return False
    top = max(wide[0] - GROUND_TAPER, 1)
    # Columns where the band has shape but nothing stands on it.
    loose = shape[top:bottom + 1].any(axis=0) & ~shape[top - 1]
    runs, start = [], None
    for x, v in enumerate(np.append(loose, False)):
        if v and start is None:
            start = x
        elif not v and start is not None:
            runs.append((start, x))
            start = None
    # Stretches shorter than this are the edges of feet, not ground.
    runs = [(a, b) for a, b in runs if b - a >= 12]
    if sum(b - a for a, b in runs) < GROUND_SPAN:
        return False
    for a, b in runs:
        shape[top:bottom + 1, a:b] = False
    return True


def path_data(curves):
    def pt(p):
        return "%.2f %.2f" % (p.x, p.y)

    d = []
    for curve in curves:
        d.append("M" + pt(curve.start_point))
        for seg in curve.segments:
            if seg.is_corner:
                d.append("L" + pt(seg.c) + "L" + pt(seg.end_point))
            else:
                d.append("C" + pt(seg.c1) + " " + pt(seg.c2) + " " + pt(seg.end_point))
        d.append("Z")
    return "".join(d)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("image", help="black shape on white, square")
    parser.add_argument("out", help="the SVG to write")
    parser.add_argument("--mask", help="white over the part to keep, black elsewhere")
    parser.add_argument("--keep-ground", action="store_true",
                        help="keep a ground line under the subject")
    args = parser.parse_args()
    shape = load_grey(args.image) < THRESHOLD
    if not shape.any():
        sys.exit("no shape found; is the image black on white?")
    if not args.keep_ground and remove_ground(shape):
        print("removed a ground line")
    if args.mask:
        shape &= load_grey(args.mask) >= THRESHOLD
    # potracer fills the False pixels, as a black pixel is 0 in a 1-bit image.
    curves = potrace.Bitmap(~shape).trace(turdsize=TURD_SIZE, alphamax=1.0, opticurve=True)
    # Holes come back as curves inside curves; even-odd filling cuts them out.
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'
           '<path fill="#fff" fill-rule="evenodd" d="%s"/></svg>\n'
           % (SIZE, SIZE, SIZE, SIZE, path_data(curves)))
    with open(args.out, "w") as f:
        f.write(svg)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
