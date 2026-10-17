"""Split a layered silhouette from Illustrator into the layers of a rig.

    python3 tools/split_rig.py art/creatures/grimroch-parts.svg grimroch
    python3 tools/split_rig.py --head-only art/creatures/vuurhast-parts.svg vuurhast

The source is one 512 x 512 artboard, drawn in black. The `head` layer is the part
that moves on its own, and a named sublayer or object inside it (the jaw) moves with
it. Every other layer (the body, and any arms, tail or wings drawn on layers of their
own) is drawn into the body, in the order the layers are stacked; those bend with the
body by soft bones (Art.BONES) rather than coming apart.

Each layer is separated from what is drawn below it by a gap: its white offset path
where it has one, or else its shapes outlined GAP units wide, as an offset of that
size would be. A head never cuts its own jaw: the two are drawn as one piece.

Circles named `<name>-joint` (or `<name>-pivot`) or `<name>-tip`, on any layer, are points: `head-joint`
and `jaw-joint` are what the head and jaw turn about, and the others place soft bones.
They are only read, never drawn.

Writes, beside the source:
  <name>-rig-<part>.svg  body, head and jaw on the full 512 canvas, recoloured for the
                         shader: the part white, its gap black (alpha is where it
                         covers, red is where it draws; see creature_idle.gdshader)
  <name>-rig.json        the parts in drawing order, each with its pivot and parent,
                         and every point by name
  <name>-rig-head-whole.svg  the head and jaw as one plain white silhouette, for the
                         places that show the head alone
  <name>.svg             the whole creature the same way, for small and still uses
                         (replacing the one there, so it always matches the layers)

--head-only writes only <name>-rig-head-whole.svg, for a creature whose layers are
needed only for its head shown alone.

Illustrator adds _1_, _2_ to a name it has seen before, even after the other is
gone; those are dropped. Shapes with no fill are invisible and left out.
"""

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

SVG = "{http://www.w3.org/2000/svg}"
SHAPES = {"path", "polygon", "polyline", "rect", "circle", "ellipse"}
# How far a made gap reaches past a layer's edge, in 512 units.
GAP = 2.0
# Paint and naming attributes are replaced; the geometry is copied as it is.
DROP = {"id", "fill", "stroke", "stroke-width", "stroke-miterlimit", "opacity", "style"}
# Marks the files this tool writes, so it never replaces one drawn by hand.
MADE = "made by tools/split_rig.py"


def tag(el):
    return el.tag.replace(SVG, "")


def name_of(el):
    """An element's name, without Illustrator's _1_ suffixes; a `-pivot` is a `-joint`."""
    raw = el.get("id")
    if not raw:
        return None
    return re.sub(r"-pivot$", "-joint", re.sub(r"_\d+_$", "", raw))


def is_point(el):
    n = name_of(el)
    return n is not None and (n.endswith("-joint") or n.endswith("-tip"))


def is_gap(el):
    """White, or near it (Illustrator sometimes leaves an offset at #FDFDFF)."""
    fill = (el.get("fill") or "").lower()
    if fill == "white":
        return True
    if not re.fullmatch(r"#[0-9a-f]{3}|#[0-9a-f]{6}", fill):
        return False
    digits = fill[1:] if len(fill) == 7 else "".join(c * 2 for c in fill[1:])
    return all(int(digits[i:i + 2], 16) >= 0xE0 for i in (0, 2, 4))


def geometry(el):
    return {k: v for k, v in el.attrib.items() if k not in DROP} | {"_tag": tag(el)}


class Shape:
    def __init__(self, order, el, layer):
        self.order = order
        self.el = el
        self.gap = is_gap(el)
        # The source layer it was drawn on, which its made gap goes with.
        self.layer = layer


class Part:
    def __init__(self, name, parent):
        self.name = name
        self.parent = parent
        self.shapes = []

    def first(self):
        return min(s.order for s in self.shapes)


def walk(el, part, layer, parts, order):
    """Gather the shapes under `el` into `part`; named children start parts of their own."""
    children = list(el)
    for i, child in enumerate(children):
        kind = tag(child)
        name = name_of(child)
        if is_point(child):
            continue
        if name is not None and kind in SHAPES | {"g"}:
            sub = Part(name, part.name)
            parts.append(sub)
            # A named shape's gap is the unnamed white offset path Illustrator puts
            # just below it.
            if kind != "g" and i > 0 and part.shapes:
                prev = children[i - 1]
                last = part.shapes[-1]
                if last.el is prev and last.gap and name_of(prev) is None:
                    part.shapes.pop()
                    sub.shapes.append(Shape(last.order, prev, name))
            if kind == "g":
                walk(child, sub, name, parts, order)
            else:
                order[0] += 1
                sub.shapes.append(Shape(order[0], child, name))
        elif kind == "g":
            walk(child, part, layer, parts, order)
        elif kind in SHAPES and (child.get("fill") or "").lower() != "none":
            order[0] += 1
            part.shapes.append(Shape(order[0], child, layer))


def by_layer(part):
    """The part's shapes grouped by the layer they were drawn on, bottom first."""
    groups = {}
    for s in sorted(part.shapes, key=lambda s: s.order):
        groups.setdefault(s.layer, []).append(s)
    return list(groups.values())


def gaps(shapes):
    """A layer's gap: its white offset paths, or where it has none, its shapes
    outlined GAP wide, which covers what such an offset would."""
    drawn = [geometry(s.el) for s in shapes if s.gap]
    if drawn:
        return drawn
    return [geometry(s.el) | {"stroke": "#000", "stroke-width": str(GAP * 2), "stroke-linejoin": "round"}
            for s in shapes]


def add(parent, shape, fill):
    attrs = {k: v for k, v in shape.items() if k != "_tag"}
    attrs["fill"] = fill
    ET.SubElement(parent, shape["_tag"], attrs)


def canvas():
    return ET.Element("svg", {
        "xmlns": "http://www.w3.org/2000/svg",
        "width": "512", "height": "512", "viewBox": "0 0 512 512",
    })


def save(root, path, mark=False):
    text = ET.tostring(root, encoding="unicode") + "\n"
    path.write_text((f"<!-- {MADE} -->\n" if mark else "") + text, encoding="utf-8")


def write_part(part, path):
    """One part for the shader: each of its layers' gaps black, its shapes white."""
    root = canvas()
    for shapes in by_layer(part):
        if not any(s.gap for s in shapes):
            for shape in gaps(shapes):
                add(root, shape, "#000")
        for s in shapes:
            add(root, geometry(s.el), "#000" if s.gap else "#fff")
    save(root, path)


def ours(path):
    """True when `path` is missing or was written by this tool."""
    return not path.exists() or MADE in path.read_text(encoding="utf-8", errors="ignore")[:200]


def pieces(parts):
    """The parts in drawing order, a part and the part it carries side by side
    grouped as one piece (a head and its jaw), so neither cuts the other."""
    out = []
    for p in parts:
        last = out[-1][-1] if out else None
        if last is not None and (p.parent == last.name or last.parent == p.name):
            out[-1].append(p)
        else:
            out.append([p])
    return out


def write_whole(parts, path):
    """Parts drawn as one plain white silhouette, for places that show them still.
    Layer by layer, bottom first, each layer's gap is cut out of everything below
    it, except that a piece's own layers (a head and its jaw) don't cut each other."""
    root = canvas()
    defs = ET.SubElement(root, "defs")
    below = None
    n = 0
    for piece in pieces(parts):
        cut, drawn = [], []
        for part in piece:
            for shapes in by_layer(part):
                if len(piece) == 1 and below is not None:
                    # Within one part, each layer cuts what came before it.
                    below, n = masked(defs, below, gaps(shapes), n)
                elif len(piece) > 1:
                    cut += gaps(shapes)
                drawn.append(shapes)
                if len(piece) == 1:
                    below = draw(below, [shapes])
        if len(piece) > 1:
            if below is not None:
                below, n = masked(defs, below, cut, n)
            below = draw(below, drawn)
    root.append(below)
    save(root, path, mark=True)


def masked(defs, below, cut, n):
    """`below` with the `cut` shapes taken out of it."""
    mask = ET.SubElement(defs, "mask", {"id": f"gap{n}", "maskUnits": "userSpaceOnUse",
                                        "x": "0", "y": "0", "width": "512", "height": "512"})
    ET.SubElement(mask, "rect", {"width": "512", "height": "512", "fill": "#fff"})
    for shape in cut:
        add(mask, shape, "#000")
    group = ET.Element("g", {"mask": f"url(#gap{n})"})
    group.append(below)
    return group, n + 1


def draw(below, layers):
    """`below` with the layers' shapes drawn white over it."""
    group = ET.Element("g")
    if below is not None:
        group.append(below)
    for shapes in layers:
        for s in shapes:
            if not s.gap:
                add(group, geometry(s.el), "#fff")
    return group


def centre(el):
    kind = tag(el)
    if kind in ("circle", "ellipse"):
        return [round(float(el.get("cx")), 2), round(float(el.get("cy")), 2)]
    raise SystemExit(f"{name_of(el)} is a {kind}; draw points as circles")


def main():
    args = sys.argv[1:]
    head_only = "--head-only" in args
    args = [a for a in args if a != "--head-only"]
    if len(args) != 2:
        raise SystemExit(__doc__)
    source = Path(args[0])
    name = args[1]
    svg = ET.parse(source).getroot()
    box = (svg.get("viewBox") or "").split()
    if [float(v) for v in box] != [0, 0, 512, 512]:
        raise SystemExit(f"{source} must be a 512 x 512 artboard, not viewBox {box}")

    whole = source.parent / f"{name}.svg"
    if not head_only and not ours(whole):
        raise SystemExit(f"{whole} was not made by this tool (an export from Illustrator?); "
                         f"nothing written. Export to {name}-parts.svg, or move it aside, and run again")

    points = {name_of(el): centre(el) for el in svg.iter() if is_point(el)}
    body = Part("body", None)
    parts, order = [body], [0]
    for layer in svg:
        if tag(layer) != "g":
            continue
        lname = name_of(layer)
        if lname is None:
            raise SystemExit("every top-level layer needs a name")
        if lname == "head":
            head = Part("head", None)
            parts.append(head)
            walk(layer, head, "head", parts, order)
        else:
            walk(layer, body, lname, parts, order)

    parts = [p for p in parts if p.shapes]
    names = [p.name for p in parts]
    if len(set(names)) != len(names):
        raise SystemExit(f"two parts share a name: {names}")
    # Drawn bottom to top, each part where its first shape is stacked.
    parts.sort(key=Part.first)

    head = [p for p in parts if p.name == "head" or p.parent == "head"]
    if head:
        write_whole(head, source.parent / f"{name}-rig-head-whole.svg")
        print(f"{name}-rig-head-whole.svg  {[p.name for p in head]}")
    elif head_only:
        raise SystemExit(f"{source} has no head layer")
    if head_only:
        return

    layers = []
    for p in parts:
        art = f"{name}-rig-{p.name}"
        write_part(p, source.parent / f"{art}.svg")
        pivot = points.get(f"{p.name}-joint")
        layers.append({"name": p.name, "art": art, "pivot": pivot, "parent": p.parent})
        print(f"{art}.svg  pivot {pivot}  parent {p.parent}  layers {[g[0].layer for g in by_layer(p)]}")
    write_whole(parts, whole)
    print(f"{name}.svg  the whole")
    rig = {"source": source.name, "layers": layers, "points": points}
    (source.parent / f"{name}-rig.json").write_text(json.dumps(rig, indent="\t") + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
