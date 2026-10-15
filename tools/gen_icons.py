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
DISC = "M24 2 a22 22 0 1 0 0.01 0 Z"


def uv_poly(x0, y0, w, h, uv):
    """Points given as fractions of a box, matching the card face's own shapes."""
    return poly(" ".join("%.2f,%.2f" % (x0 + u * w, y0 + v * h) for u, v in uv))


BANNER = [(0, 0), (1, 0), (0.955, 0.2), (0.935, 0.4), (0.94, 0.6), (0.96, 0.8), (1, 1), (0.5, 0.82),
          (0, 1), (0.04, 0.8), (0.06, 0.6), (0.065, 0.4), (0.045, 0.2)]
SHIELD = [(0.5, 0), (1, 0.2), (0.98, 0.55), (0.92, 0.72), (0.8, 0.85), (0.5, 1), (0.2, 0.85), (0.08, 0.72),
          (0.02, 0.55), (0, 0.2)]


def circle(cx, cy, r):
    return "M%g %g a%g %g 0 1 0 0.01 0 Z" % (cx, cy - r, r, r)


def ring(cx, cy, outer, inner):
    return circle(cx, cy, outer) + " " + circle(cx, cy, inner)


def badge(cutout):
    """A Hardship, enemy Ability or Journey Peril: a solid disc with its picture cut
    out of it, as printed. Shapes nested inside a cut-out are solid again."""
    return path(DISC + " " + cutout)


def burst(cx, cy, outer, inner, points=8):
    pts = []
    for i in range(points * 2):
        r = outer if i % 2 == 0 else inner
        a = math.radians(-90 + i * 180 / points)
        pts.append("%.2f %.2f" % (cx + r * math.cos(a), cy + r * math.sin(a)))
    return "M" + " L".join(pts) + " Z"


def bar(x1, y1, x2, y2, w):
    """A thin straight streak from one point to another, as a closed shape."""
    dx, dy = x2 - x1, y2 - y1
    n = math.hypot(dx, dy)
    ox, oy = -dy / n * w / 2, dx / n * w / 2
    return "M%.2f %.2f L%.2f %.2f L%.2f %.2f L%.2f %.2f Z" % (x1 + ox, y1 + oy, x2 + ox, y2 + oy, x2 - ox, y2 - oy, x1 - ox, y1 - oy)


def _snowflake():
    """Six flared arms around a hexagonal hub, as one outline."""
    pts = []
    for k in range(6):
        t = math.radians(-90 + k * 60)
        u, v = (math.cos(t), math.sin(t)), (-math.sin(t), math.cos(t))
        at = lambda r, s: "%.2f %.2f" % (24 + u[0] * r + v[0] * s, 24 + u[1] * r + v[1] * s)
        h = math.radians(-90 + k * 60 - 30)
        pts.append("%.2f %.2f" % (24 + 7 * math.cos(h), 24 + 7 * math.sin(h)))
        pts += [at(7, -2.6), at(13, -2.6), at(13.5, -6), at(19.5, -3.2), at(18, 0), at(19.5, 3.2), at(13.5, 6), at(13, 2.6), at(7, 2.6)]
    return "M" + " L".join(pts) + " Z"


def _crescent(ax, ay, ar, bx, by, br):
    """Circle A with circle B bitten out of it, as one outline."""
    d = math.hypot(bx - ax, by - ay)
    a = (ar * ar - br * br + d * d) / (2 * d)
    h = math.sqrt(ar * ar - a * a)
    mx, my = ax + a * (bx - ax) / d, ay + a * (by - ay) / d
    p1 = (mx + h * (by - ay) / d, my - h * (bx - ax) / d)
    p2 = (mx - h * (by - ay) / d, my + h * (bx - ax) / d)
    return "M%.2f %.2f A%g %g 0 1 0 %.2f %.2f A%g %g 0 0 1 %.2f %.2f Z" % (p1 + (ar, ar) + p2 + (br, br) + p1)

ICONS = {
    # Ether elements, in the shapes printed beside each card's name
    "fire": path("M24 45 C15 45 9 39 9 31 C9 24 10.5 17 12.5 10 C14.5 16 17 20.5 20.5 23 C20 14 24 7.5 32 2"
                 " C30.5 11 39 17 39 29.5 C39 38.5 32 45 24 45 Z"),
    "water": path("M24 2 C24 2 39 21 39 31 A15 15 0 0 1 9 31 C9 21 24 2 24 2 Z"),
    "lightning": poly("30,1 10,27 21,27 15,47 38,19 27,19 37,1"),
    "shadow": path("M24 1 Q26.4 21.6 43 24 Q26.4 26.4 24 47 Q21.6 26.4 5 24 Q21.6 21.6 24 1 Z"),
    # Card stats
    # A longsword: tapered blade with a fuller, flared crossguard, grip and pommel.
    "attack": path("M24 1 L29.5 8 L29.5 29.5 L18.5 29.5 L18.5 8 Z M23 10 L25 10 L25 26.5 L23 26.5 Z"
                   " M5.5 26.5 L13 29.5 L35 29.5 L42.5 26.5 L39.5 34.5 L8.5 34.5 Z M21 34.5 L27 34.5 L27 39.1 L21 39.1 Z"
                   " M19.8 43.3 A4.2 4.2 0 1 0 28.2 43.3 A4.2 4.2 0 1 0 19.8 43.3 Z"),
    # The printed boot: tilted cuff, narrow shaft notched under it, rounded toe.
    "move": path("M10 8 Q10 5 13 4.8 L33 3.2 Q36.5 3 36.5 6.5 L36.5 12.5 Q36.5 15.5 33.5 15.5 L29.5 16.5 L29.5 26"
                 " Q31 29.5 37 30.5 Q44.5 31.8 44.5 38.5 L44.5 41 Q44.5 43.5 42 43.5 L13.5 43.5 Q11.5 43.5 11.5 41.5"
                 " L11.5 17 Q10 16 10 14 Z"),
    # The printed Initiative banner and Armor shield, as drawn on the card face.
    "initiative": uv_poly(6, 3, 36, 42, BANNER),
    "armor": uv_poly(5, 2, 38, 44, SHIELD),
    # A block with a square step cut from each corner, like the printed Boost plate.
    "boost": path("M11 4 H37 V11 H44 V37 H37 V44 H11 V37 H4 V11 H11 Z"),
    "xp": path(burst(24, 24, 23, 14)),
    # Badge shapes that hold a number, as on the printed Region card: an enemy's
    # Attack flame, a Journey's MP mountain and its Time Penalty hourglass.
    "attack_badge": path("M30 3 C29 10 39 16 39 30 C39 39 32 45 24 45 C15 45 9 39 9 31 C9 23 12 18 14 13"
                         " C16 18 18 20 21 21 C21 13 24 7 30 3 Z"),
    # The printed MP mountain: a jagged main peak with a notch and a lower right peak.
    "mp_badge": path("M2 44 L13 24 L16 25.5 L23 6 L27 13 L30.5 9 L39 26 L41.5 25 L46 44 Z"),
    # The printed hourglass: flat caps over a body drawn in to a waist.
    "time_badge": path("M5 3 H43 V10 L38 13 Q32 24 38 35 L43 38 V45 H5 V38 L10 35 Q16 24 10 13 L5 10 Z"),
    "upgrade": path(burst(24, 24, 23, 14) + " M24 12 L32.5 21.5 L27.5 21.5 L27.5 33 L20.5 33 L20.5 21.5 L15.5 21.5 Z"),
    # The printed Level crown: wider at the top, a tall tipped centre point, flared
    # outer points, and a separate band beneath.
    "crown": poly("10,38 6.5,15 3,6 8,12.5 14,17 20.5,9 19.5,7 24,1.5 28.5,7 27.5,9 34,17 40,12.5 45,6 41.5,15 38,38")
             + '<rect x="8" y="41" width="32" height="4"/>',
    # Records: a cup with two handles on a short stem, a foot and a plinth.
    "trophy": path("M12 3 H36 V13 C36 21.5 31 26.5 24 27.5 C17 26.5 12 21.5 12 13 Z")
              + path("M12 6 H6 Q3.5 6 3.5 9 C3.5 15.5 7.5 19.5 12 20 V16 C9.5 15.5 7.5 13 7.5 10 H12 Z")
              + path("M36 6 H42 Q44.5 6 44.5 9 C44.5 15.5 40.5 19.5 36 20 V16 C38.5 15.5 40.5 13 40.5 10 H36 Z")
              + path("M21.5 27.5 H26.5 V35 H21.5 Z M15 35 H33 V39 H15 Z M11 41 H37 V45 H11 Z"),
    # Encounters
    # A skull with cheekbones and a row of teeth, as printed.
    "enemy": path("M24 3 C35 3 43 10 43 20 C43 25.5 41 28.5 38 30.5 L37 37 L35 44 L30.5 44 L30.5 38.5 L28.5 38.5"
                  " L28.5 44 L25 44 L25 38.5 L23 38.5 L23 44 L19.5 44 L19.5 38.5 L17.5 38.5 L17.5 44 L13 44 L11 37"
                  " L10 30.5 C7 28.5 5 25.5 5 20 C5 10 13 3 24 3 Z"
                  " M16 15.5 a5.5 5.5 0 1 0 0.01 0 Z M32 15.5 a5.5 5.5 0 1 0 0.01 0 Z M24 26 L27 32 L21 32 Z"),
    # A post with a board pointing each way, as printed.
    "journey": poly("6,4 37,4 43,10 37,16 6,16") + poly("11,19 42,19 42,30 11,30 5,24.5") + poly("21.5,16 26.5,16 26.5,46 21.5,46"),
    "hp": path("M24 44 C7 31 3 23 3 15 A10.5 10.5 0 0 1 24 11 A10.5 10.5 0 0 1 45 15 C45 23 41 31 24 44 Z"),
    # One mountain with a path winding up its face.
    "mp": path("M2 43 L13 24 L17 28 L28 5 L46 43 Z M27 43 C33 38 19 34 25 27 C27.5 24 29 21 29 17 L30.5 17"
               " C31 22 29.5 25.5 27.5 28 C23 33.5 37 38 31.5 43 Z"),
    "time": poly("9,3 39,3 39,8 28,24 39,40 39,45 9,45 9,40 20,24 9,8"),
    # Hardships
    # A hooded face over a band of shoulders.
    "ambush": badge("M11 35 V22 Q11 8 24 8 Q37 8 37 22 V35 Q24 31.5 11 35 Z"
                    " M16.5 31 V24 Q16.5 14 24 14 Q31.5 14 31.5 24 V31 Q24 28.5 16.5 31 Z"
                    " M18.5 22.5 L23 24.5 L22 26.5 L18.5 25 Z M29.5 22.5 L25 24.5 L26 26.5 L29.5 25 Z"),
    # A billowing cloud with a curl, over the ground.
    "hazards": badge("M9 36 C5 31 8 23 15 24 C13 16 21 11 27 15 C30 9 39 11 38 18 C43 20 42 28 37 30"
                     " C35 33 31 33 29 31 C29 35 26 36.5 23 36.5 Z"
                     " M28 21 C33.5 21 34.5 28.5 29 29.5 C25.5 30 23.5 26.5 25.5 24.5 C27 23.2 29 24.5 28 26"
                     " C30.5 26 30.5 23 28 23 C24.5 23 22.5 26.5 24 29.5 L22 30 C20 25 23 21 28 21 Z"),
    # A crescent cradling a four-point star.
    "night_travel": badge(_crescent(23, 25, 16, 30, 20, 12.5)
                          + " M30 13 Q31 19 36.5 20 Q31 21 30 27 Q29 21 23.5 20 Q29 19 30 13 Z"),
    # A bolt with streaks of rain.
    "storm": badge("M30 6 L16 25 H23.5 L18.5 36 L35 17 H27.5 L33 6 Z" + " " + bar(14.5, 35, 9.5, 38.5, 2.4)
                   + " " + bar(18.5, 39.5, 16, 44, 2.4) + " " + bar(23.5, 38.5, 25, 43.5, 2.4)),
    # Enemy abilities
    # A six-armed snowflake around a small star.
    "freeze": badge(_snowflake() + " " + burst(24, 24, 4, 2, 6)),
    # A drop with a drip running inside it.
    "poison": badge("M24 7 C28 14 35.5 21 35.5 29 C35.5 36 30.5 41 24 41 C17.5 41 12.5 36 12.5 29 C12.5 21 20 14 24 7 Z"
                    " M28.5 25 C29.5 28.5 31.5 30.5 31.5 33 C31.5 35.2 30 36.5 28.5 36.5 C27 36.5 25.5 35.2 25.5 33"
                    " C25.5 30.5 27.5 28.5 28.5 25 Z"),
    # An arrow in flight, up and to the right, with speed streaks.
    "ranged": badge("M37 9 L35 23 L30.5 18.5 L15 34 L12.5 31.5 L28 16 L23.5 11.5 Z" + " " + bar(9, 26, 20, 15, 1.8)
                    + " " + bar(20, 38, 31, 27, 1.8)),
    "slow": badge("M24 12 L28 12 L19.5 24 L28 36 L24 36 L15.5 24 Z M34 12 L38 12 L29.5 24 L38 36 L34 36 L25.5 24 Z"),
    # Journey perils
    # Two snow-capped peaks inside a ring.
    "steep": badge("M8.1 30 A17 17 0 1 1 39.9 30 L29 10 L22 21 L17 14 Z"
                   " M17 15.8 L19.8 19.4 L18.5 18.4 L17 20.2 L15.6 18.4 L14.4 19.4 Z"
                   " M29 11.8 L31.9 16.6 L30.2 15.4 L28.6 17.6 L27.1 15.4 L25.6 16.6 Z"),
    # Rock shards tumbling.
    "treacherous": badge("M20 8 L30 10 L33 19 L26 24 L18 19 Z M9 26 L17 23 L19.5 31 L12.5 35 Z M27 28 L36 25 L38.5 34 L30 37.5 Z"),
}



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

# The dragons' marks keep the shapes they were drawn with.
_OLD_FLAME = path("M29 2 C30 10 38 15 39 26 C40 37 33 45 23.5 45 C14.5 45 9 38.5 9 31 C9 23 15 19 18 12"
                  " C19 18 21 21 24 22 C22 15 24 7 29 2 Z")

# Large, faint emblems drawn behind card and Encounter faces.
SIGILS = {
    "sigil_fire": sigil(ICONS["fire"]),
    "sigil_water": sigil(ICONS["water"]),
    "sigil_lightning": sigil(ICONS["lightning"]),
    "sigil_shadow": sigil(ICONS["shadow"]),
    "sigil_grimroch": dragon_sigil(path("M24 2 L43 8 V24 C43 35 35 42 24 46 C13 42 5 35 5 24 V8 Z"), _HORNS_WIDE),
    "sigil_helsang": dragon_sigil(path("M24 3 C12 3 5 11 5 21 C5 27 8 32 13 34 V43 H35 V34 C40 32 43 27 43 21 C43 11 36 3 24 3 Z"
                                       " M16 17 a5 5 0 1 0 0.01 0 Z M32 17 a5 5 0 1 0 0.01 0 Z M22 30 L24 25 L26 30 Z"), _HORNS_CROWN),
    "sigil_rodving": dragon_sigil(_OLD_FLAME, _HORNS_UP),
    "sigil_vuurhast": dragon_sigil(path("M31 3 A21 21 0 1 0 45 31 A17 17 0 0 1 31 3 Z"), _HORNS_DOWN),
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
