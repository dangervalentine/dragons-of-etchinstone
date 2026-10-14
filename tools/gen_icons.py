"""Writes the icon set to art/icons/ as white 48-unit SVGs; the game tints them.

Run: python3 tools/gen_icons.py
"""
import math
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "art", "icons")


def star(cx, cy, outer, inner, points=5):
    pts = []
    for i in range(points * 2):
        r = outer if i % 2 == 0 else inner
        a = math.radians(-90 + i * 180 / points)
        pts.append("%.1f,%.1f" % (cx + r * math.cos(a), cy + r * math.sin(a)))
    return '<polygon points="%s"/>' % " ".join(pts)


def poly(points):
    return '<polygon points="%s"/>' % points


def path(d):
    return '<path fill-rule="evenodd" d="%s"/>' % d


RING = "M24 2 a22 22 0 1 0 0.01 0 Z M24 6.5 a17.5 17.5 0 1 1 -0.01 0 Z"

ICONS = {
    # Ether elements
    "fire": path("M25 3 C27 14 39 18 39 31 A15 15 0 0 1 9 31 C9 23 15 21 16 12 C19 16 22 15 25 3 Z"),
    "water": path("M24 3 C24 3 39 22 39 31 A15 15 0 0 1 9 31 C9 22 24 3 24 3 Z"),
    "lightning": poly("29,2 9,27 21,27 17,46 39,19 27,19"),
    "shadow": poly("24,2 30,18 46,24 30,30 24,46 18,30 2,24 18,18"),
    # Card stats
    "attack": poly("24,2 30,10 30,29 37,29 37,34 27,34 27,42 30,42 30,46 18,46 18,42 21,42 21,34 11,34 11,29 18,29 18,10"),
    "move": path("M15 4 H29 V25 L41 31 Q45 33 45 38 V43 H11 V33 Q15 29 15 23 Z"),
    "initiative": poly("7,3 41,3 41,45 24,36 7,45"),
    "armor": path("M24 2 L43 8 V24 C43 35 35 42 24 46 C13 42 5 35 5 24 V8 Z"),
    "boost": poly("24,3 43,24 32,24 32,45 16,45 16,24 5,24"),
    "xp": star(24, 25, 23, 9.5),
    "crown": poly("4,10 15,22 24,5 33,22 44,10 41,43 7,43"),
    # Encounters
    "enemy": path("M24 3 C12 3 5 11 5 21 C5 27 8 32 13 34 V43 H35 V34 C40 32 43 27 43 21 C43 11 36 3 24 3 Z"
                  " M16 17 a5 5 0 1 0 0.01 0 Z M32 17 a5 5 0 1 0 0.01 0 Z M22 30 L24 25 L26 30 Z"),
    "journey": poly("21,3 27,3 27,7 37,7 44,13.5 37,20 27,20 27,24 38,24 38,36 27,36 27,46 21,46 21,36 11,36 4,30 11,24 21,24 21,20 10,20 10,7 21,7"),
    "hp": path("M24 44 C7 31 3 23 3 15 A10.5 10.5 0 0 1 24 11 A10.5 10.5 0 0 1 45 15 C45 23 41 31 24 44 Z"),
    "mp": poly("2,43 17,9 25,25 31,16 46,43"),
    "time": poly("9,3 39,3 39,8 28,24 39,40 39,45 9,45 9,40 20,24 9,8"),
    # Hardships
    "ambush": path("M24 3 L46 43 H2 Z M21.5 17 H26.5 L25.5 31 H22.5 Z M24 34 a3 3 0 1 0 0.01 0 Z"),
    "hazards": poly("2,43 9,20 16,35 24,6 32,35 39,20 46,43"),
    "night_travel": path("M31 3 A21 21 0 1 0 45 31 A17 17 0 0 1 31 3 Z"),
    "storm": path(RING + " M28 10 L15 27 H23 L20 39 L34 21 H26 Z"),
    # Enemy abilities
    "freeze": "".join('<rect x="21.5" y="2" width="5" height="44" rx="2" transform="rotate(%d 24 24)"/>' % a for a in (0, 60, 120))
              + "".join('<polygon points="24,9 17,3 20,1 24,5 28,1 31,3" transform="rotate(%d 24 24)"/>' % a for a in range(0, 360, 60)),
    "poison": path("M18 3 H30 V8 H28 V18 L41 39 Q43 45 37 45 H11 Q5 45 7 39 L20 18 V8 H18 Z"
                   " M17 31 a3 3 0 1 0 0.01 0 Z M27 34 a4 4 0 1 0 0.01 0 Z"),
    "ranged": '<g transform="rotate(45 24 24)">' + poly("24,-4 34,11 27,11 27,36 33,46 24,42 15,46 21,36 21,11 14,11") + "</g>",
    "slow": poly("20,7 28,7 14,24 28,41 20,41 5,24") + poly("37,7 45,7 31,24 45,41 37,41 22,24"),
    # Journey perils
    "steep": poly("3,44 31,4 45,44"),
    "treacherous": poly("4,30 12,20 22,24 24,36 14,44 5,40") + poly("27,10 36,4 44,10 42,21 32,23")
                   + poly("29,32 38,28 45,36 40,45 31,43"),
}

for name, body in ICONS.items():
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 48 48" fill="#ffffff">'
           + body + "</svg>\n")
    with open(os.path.join(OUT, name + ".svg"), "w") as f:
        f.write(svg)
print(len(ICONS), "icons written")
