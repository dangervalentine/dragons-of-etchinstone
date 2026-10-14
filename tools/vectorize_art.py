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
    args = parser.parse_args()
    shape = load_grey(args.image) < THRESHOLD
    if args.mask:
        shape &= load_grey(args.mask) >= THRESHOLD
    if not shape.any():
        sys.exit("no shape found; is the image black on white?")
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
