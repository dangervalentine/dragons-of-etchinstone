"""Writes the icon set to art/icons/ as white 48-unit SVGs; the game tints them.
Sigils are written larger because they are drawn large.

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
    # Ether elements, in the shapes printed beside each card's name
    "fire": path("M29 2 C30 10 38 15 39 26 C40 37 33 45 23.5 45 C14.5 45 9 38.5 9 31 C9 23 15 19 18 12"
                 " C19 18 21 21 24 22 C22 15 24 7 29 2 Z"),
    "water": path("M24 2 C24 2 39 21 39 31 A15 15 0 0 1 9 31 C9 21 24 2 24 2 Z"),
    "lightning": poly("33,1 11,26 22.5,26 14,47 38,19 26.5,19 36,1"),
    "shadow": path("M24 1 Q26.4 21.6 43 24 Q26.4 26.4 24 47 Q21.6 26.4 5 24 Q21.6 21.6 24 1 Z"),
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



def circle(cx, cy, r):
    return "M%g %g a%g %g 0 1 0 0.01 0 Z" % (cx, cy - r, r, r)


def ring(cx, cy, outer, inner):
    return circle(cx, cy, outer) + " " + circle(cx, cy, inner)


def gear(cx, cy, outer, inner, teeth, hole):
    pts = []
    for i in range(teeth * 4):
        r = outer if i % 4 in (0, 1) else inner
        a = math.radians(i * 90 / teeth - 45 / teeth)
        pts.append("%.1f %.1f" % (cx + r * math.cos(a), cy + r * math.sin(a)))
    return path("M" + " L".join(pts) + " Z " + circle(cx, cy, hole))


def rotated(body, angle):
    return '<g transform="rotate(%d 24 24)">%s</g>' % (angle, body)


def scaled(body, factor, dx=0, dy=0):
    return '<g transform="translate(%g %g) scale(%g) translate(-24 -24)">%s</g>' % (24 + dx, 24 + dy, factor, body)


TICKS = "".join('<rect x="23" y="0.5" width="2" height="4" transform="rotate(%d 24 24)"/>' % a for a in range(0, 360, 30))


def sigil(body):
    """An Ether emblem: the element etched as an outline around a smaller solid copy,
    over a faint, larger flare of the same shape."""
    flare = '<g fill-opacity="0.35">%s</g>' % scaled(body, 0.98)
    outline = '<g fill="none" stroke="#ffffff" stroke-width="1.6" stroke-linejoin="round">%s</g>' % scaled(body, 0.8)
    return flare + outline + scaled(body, 0.52)


def dragon_sigil(body, horns):
    """A dragon's mark: an emblem in a diamond frame, crowned with horns."""
    frame = path("M24 5 L43 24 L24 43 L5 24 Z M24 9 L9 24 L24 39 L39 24 Z")
    return frame + horns + scaled(body, 0.42)


_ARROW = path("M24 6 A18 18 0 0 1 42 24 H47 L39 35 L31 24 H36 A12 12 0 0 0 24 12 Z")
_HORNS_UP = poly("10,2 16,12 12,14 6,8") + poly("38,2 32,12 36,14 42,8")
_HORNS_WIDE = poly("1,12 12,14 10,18 3,18") + poly("47,12 36,14 38,18 45,18")
_HORNS_CROWN = poly("24,0 27,6 21,6") + poly("12,4 17,11 13,13") + poly("36,4 31,11 35,13")
_HORNS_DOWN = poly("4,34 12,32 14,36 8,42") + poly("44,34 36,32 34,36 40,42")

ICONS.update({
    # Piles
    "deck": '<rect x="13" y="11" width="26" height="34" rx="3"/>' + path("M9 4 H31 Q34 4 34 7 V8 H12 Q10 8 10 10 V40 Q7 40 7 37 V7 Q7 4 9 4 Z"),
    "discard": '<rect x="13" y="8" width="23" height="32" rx="3" transform="rotate(-16 24 24)" fill-opacity="0.5"/>'
               '<rect x="13" y="9" width="23" height="32" rx="3" transform="rotate(10 24 24)"/>',
    "trash": path("M9 10 H18 V5 H30 V10 H39 V15 H9 Z M21 8 H27 V10 H21 Z") + poly("11,18 37,18 34,45 14,45"),
    # Roles
    "spell": poly("20,6 24,22 40,26 24,30 20,46 16,30 0,26 16,22") + poly("38,1 40,8 47,10 40,12 38,19 36,12 29,10 36,8"),
    "element_role": path("M14 6 H34 L44 18 L24 44 L4 18 Z M16 10 L10 18 H38 L32 10 Z"),
    "reserve": path(ring(24, 24, 22, 17) + " " + circle(24, 24, 8)),
    # Actions
    "fuse": path(ring(17, 24, 13, 8)) + path(ring(31, 24, 13, 8)),
    "divert": path("M8 45 V25 Q8 14 19 14 H30 V5 L45 18 L30 31 V22 H19 Q16 22 16 25 V45 Z"),
    "regroup": _ARROW + rotated(_ARROW, 180),
    "inspect": path(ring(20, 20, 16, 10.5)) + poly("29,33 33,29 46,42 42,46"),
    "menu": "".join('<rect x="6" y="%d" width="36" height="6" rx="3"/>' % y for y in (9, 21, 33)),
    "settings": gear(24, 24, 22, 16, 8, 7),
    "help": path(ring(24, 24, 22, 17.5)) + path("M17 19 a7 7 0 1 1 10.5 6 Q26 26 26 29 H22 Q22 23.5 25.5 21.6 a3 3 0 1 0 -4.5 -2.6 Z")
            + '<rect x="22" y="32" width="4" height="4" rx="1"/>',
    "book": path("M3 9 Q13 5 22.5 10 V42 Q13 37.5 3 41 Z M7 13 V35 Q13 33.5 18.5 35.5 V12.5 Q13 10 7 13 Z")
            + path("M25.5 10 Q35 5 45 9 V41 Q35 37.5 25.5 42 Z M29.5 12.5 V35.5 Q35 33.5 41 35 V13 Q35 10 29.5 12.5 Z"),
    "skip": poly("6,7 24,24 6,41") + poly("24,7 42,24 24,41"),
    "undo": path("M20 4 L4 16 L20 28 V20 H28 Q38 20 38 30 Q38 40 28 40 H16 V46 H28 Q44 46 44 30 Q44 13 28 13 H20 Z"),
    "close": rotated('<rect x="21" y="3" width="6" height="42" rx="3"/>', 45) + rotated('<rect x="21" y="3" width="6" height="42" rx="3"/>', -45),
    # Verdicts
    "victory": path(ring(24, 24, 22, 17.5)) + poly("12,25 16.5,20.5 22,26 31.5,14.5 36,19 22,35"),
    "narrow_victory": poly("4,26 10,20 20,30 38,8 44,14 20,42"),
    "loss": path(ring(24, 24, 22, 17.5)) + rotated('<rect x="21.5" y="11" width="5" height="26" rx="2"/>', 45)
            + rotated('<rect x="21.5" y="11" width="5" height="26" rx="2"/>', -45),
    "down_arrow": poly("24,45 43,24 32,24 32,3 16,3 16,24 5,24"),
    "card_back": path("M10 2 H38 Q42 2 42 6 V42 Q42 46 38 46 H10 Q6 46 6 42 V6 Q6 2 10 2 Z M24 12 L34 24 L24 36 L14 24 Z"),
})

# Large, faint emblems drawn behind card and Encounter faces.
SIGILS = {
    "sigil_fire": sigil(ICONS["fire"]),
    "sigil_water": sigil(ICONS["water"]),
    "sigil_lightning": sigil(ICONS["lightning"]),
    "sigil_shadow": sigil(ICONS["shadow"]),
    "sigil_grimroch": dragon_sigil(ICONS["armor"], _HORNS_WIDE),
    "sigil_helsang": dragon_sigil(ICONS["enemy"], _HORNS_CROWN),
    "sigil_rodving": dragon_sigil(ICONS["fire"], _HORNS_UP),
    "sigil_vuurhast": dragon_sigil(ICONS["night_travel"], _HORNS_DOWN),
    "sigil_region": path(ring(24, 24, 22, 20.5)) + scaled(ICONS["mp"], 0.6, 0, 1) + TICKS,
}

for name, body in list(ICONS.items()) + list(SIGILS.items()):
    side = 320 if name in SIGILS else 96
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 48 48" fill="#ffffff">' % (side, side)
           + body + "</svg>\n")
    # LF on every OS, as .gitattributes asks, so a rerun on Windows changes nothing.
    with open(os.path.join(OUT, name + ".svg"), "w", newline="\n") as f:
        f.write(svg)
print(len(ICONS) + len(SIGILS), "icons written")
