"""Cut the static figure fonts the numeral styles use from Fraunces (specs/019 research R3).

Fraunces ships no tabular figures, so sums, counters and tables would not line up.
This takes one static instance of the variable font per numeral style (its weight
and optical size, SOFT 50, WONK 0) and gives the ten digits one advance, the widest
digit's, each centred in it. The result is renamed, as the SIL OFL asks of a
modified font, and written next to the original:

    uv run --no-project --with fonttools python -I tools/make_figures.py

Re-run it only when art/fonts/Fraunces.ttf or the numeral styles in
ui/theme/tokens.gd change; ui/theme/theme.gd loads its output by these names.
"""

from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

FONTS = Path(__file__).resolve().parent.parent / "art" / "fonts"
SOURCE = FONTS / "Fraunces.ttf"
# (weight, optical size) of NUMERAL_XL, NUMERAL and NUMERAL_SM in tokens.gd.
STYLES = [(900, 72), (800, 24), (800, 14)]
FAMILY = "Etchinstone Figures"


def tabular(font: TTFont) -> int:
    """Give the digits the widest digit's advance, each centred; return that advance."""
    cmap = font.getBestCmap()
    glyf = font["glyf"]
    hmtx = font["hmtx"]
    names = [cmap[ord(d)] for d in "0123456789"]
    widest = max(hmtx[n][0] for n in names)
    for n in names:
        advance, lsb = hmtx[n]
        dx = round((widest - advance) / 2)
        g = glyf[n]
        if g.isComposite():
            for c in g.components:
                c.x += dx
        elif g.numberOfContours > 0:
            g.coordinates.translate((dx, 0))
        g.recalcBounds(glyf)
        hmtx[n] = (widest, lsb + dx)
    return widest


def rename(font: TTFont, style: str) -> None:
    full = f"{FAMILY} {style}"
    for rec in font["name"].names:
        if rec.nameID in (1, 16):
            rec.string = FAMILY
        elif rec.nameID in (2, 17):
            rec.string = style
        elif rec.nameID == 4:
            rec.string = full
        elif rec.nameID == 6:
            rec.string = full.replace(" ", "")


def main() -> None:
    for weight, opsz in STYLES:
        font = TTFont(SOURCE)
        static = instancer.instantiateVariableFont(
            font, {"wght": weight, "opsz": opsz, "SOFT": 50, "WONK": 0}, updateFontNames=False)
        widest = tabular(static)
        rename(static, f"{weight} {opsz}")
        out = FONTS / f"FrauncesFigures-{weight}-{opsz}.ttf"
        static.save(out)
        print(f"{out.name}: digits {widest} units wide, {out.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
