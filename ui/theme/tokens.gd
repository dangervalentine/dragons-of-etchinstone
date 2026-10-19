extends RefCounted
## The game's visual language: every size, colour, typeface and duration.
## Sizes are design units: one pixel of the 1280 x 720 landscape layout, about
## half a point on a phone held sideways. Widgets take their values from here.

# Space
const XS := 4
const S := 8
const M := 16
const L := 24
const XL := 40
const RADIUS_S := 8
const RADIUS_M := 14
const RADIUS_CARD := 16
## Nothing interactive is smaller than this on its shorter side.
const TAP_MIN := 88
## Nothing that has to be read is set smaller than this.
const TEXT_MIN := 22

# Type: [font, size]. Fonts are named in theme.gd.
# The display face (Cinzel) is for titles, names, verdicts and the figures on game
# pieces. The body face (Alegreya Sans) is for everything read as text, and for
# everything pressed: a button's words, a tile's title, a slot's role.
const TITLE := ["display_bold", 64]
## The game's name on the title screen and the verdict on the ending.
const BANNER := ["display_bold", 50]
## A screen's own subject: the chosen dragon's name, the size notice.
const H1 := ["display_bold", 40]
const HEADING := ["display", 30]
## The title of an explanation, a popup or a small panel.
const SUBHEAD := ["display_bold", 24]
## A small gold heading in capitals over a group of choices.
const EYEBROW := ["display", 24]
## Figures: small in a sum or a table, normal as a total, medium in a role slot,
## large as a purse.
const NUMERAL_S := ["display_bold", 24]
const NUMERAL := ["display_bold", 32]
const NUMERAL_M := ["display_bold", 44]
const NUMERAL_L := ["display_bold", 52]
const BODY := ["body", 26]
const LABEL := ["body_medium", 22]
const LABEL_BOLD := ["body_bold", 22]
const BUTTON := ["body_bold", 26]

# Colour roles
const BG_BASE := Color("100e17")
const BG_SURFACE := Color("1d1a29")
const BG_RAISED := Color("2b2640")
const BG_BAND := Color("15121d")
const LINE_SOFT := Color("3d3757")
const INK := Color("f1ecdf")
const INK_MUTED := Color("a69fb8")
const GOLD := Color("f2d16b")
const GOOD := Color("6fcf8e")
const CAUTION := Color("e9b44c")
const BAD := Color("ff6b5e")
const HP := Color("d2536a")
## The printed cards' Ether hues: saturated, so a card reads as its Ether at a glance.
const ETHER := {
	"fire": Color("c8261d"), "water": Color("1f5fd0"),
	"lightning": Color("e99a1c"), "shadow": Color("6b34c0"),
}
## Which character the card field shader draws for each Ether.
const ETHER_ID := {"fire": 0, "water": 1, "lightning": 2, "shadow": 3}
const DISABLED_ALPHA := 0.45
## The rim and glow on whatever matters in the current step, on cards and slots alike.
const FOCUS := Color("ffe08a")
## How far an accent drawn as an edge or a face (a selected card's border, a slot's
## Ether edge, Play's gold) steps toward the boxes' face colour, so it sits with the
## muted ground rather than shouting over it (owner, stage B review). Text and
## numerals keep their full colours.
const ACCENT_MUTE := 0.4
## Play's gold face, muted: BG_BASE text on it keeps well over 4.5:1.
const GOLD_FACE := Color("c9ad62")
## The near-black of a Mage Card's frame and bands.
const CARD_FRAME := Color("0d0b10")
## The Key Card strip under the name.
const BRONZE := Color("5a4632")
const BRONZE_DARK := Color("3a2c1f")
const BRONZE_LIGHT := Color("a88a63")
## The Deck seen from the side (feature 014): each card's edge in card stock, and
## the line between one card and the next. Never an Ether's colour.
const CARD_EDGE := Color("8d8778")
const CARD_EDGE_LINE := Color("4a463e")

# Layout
## The margin the Deck's card edges take on the right and bottom of the left side.
const DECK_EDGE := 24
## The narrowest the left column gets (feature 013): it fixes the smallest whole
## Region Card, whose figures must still read at TEXT_MIN.
const LEFT_MIN_W := 400
## How long a refused Play's reason lies on the Deck in the card's place (feature 013).
const NOTE_HOLD := 2.4
## The least height of a note on the Deck that sets the result out line by line.
const NOTE_ROOMY_H := 360

# Stone
## The luminance band the stone grain is remapped into. The top stays no lighter
## than BG_RAISED, so text keeps its contrast on the brightest stone.
const STONE_L_MIN := 0.008
const STONE_L_MAX := 0.022
## Cut-corner sizes: small chips, wells and buttons, slabs.
const CHAMFER_S := 6
const CHAMFER_M := 12
const CHAMFER_L := 20
## The edges of a carved bevel.
const BEVEL_LIGHT := Color(1, 1, 1, 0.10)
const BEVEL_SHADOW := Color(0, 0, 0, 0.45)

# Responses
## The colour of a board response that has no Ether of its own: a cold violet.
const RESPONSE_NEUTRAL := Color("8f7fd6")

# Motion, in seconds
const INSTANT := 0.08
const FAST := 0.15
const BASE := 0.25
const MOVE := 0.35
const COUNT := 0.6
const REVEAL := 0.4
const STAGGER := 0.12
const SEQUENCE_MAX := 3.0
## The Deck (feature 012): zooming between the top card and a face, turning the
## Region Card, and the Key Card rising from under it and, as the zoom starts,
## sliding back.
const ZOOM := 0.55
const TURN := 0.5
const PEEK_RISE := 0.25
const PEEK_FALL := 0.2
## A drawn card's flight from the top card, at its size, to its place in the Hand
## (feature 014).
const DRAW_FLY := 0.45
## The Key Card's Encounter number lighting up once it has risen.
const KEY_LIT := 0.35
## The matching panel on the Region Card lighting up, from 60% of KEY_LIT.
const PANEL_LIT := 0.45
## The whole reveal on the Deck: the rise, the number lit, the panel lit and the hold
## with the Key Card still up, until the zoom slides it back down.
const KEY_PEEK := 1.05

# The landscape layout
const DESIGN_MIN := Vector2(1280, 720)
const DESIGN_MAX := Vector2(1760, 990)
## Width over height of a Mage Card.
const CARD_ASPECT := 190.0 / 266.0

const VERDICT := {
	"complete": {"text": "Complete victory", "icon": "victory", "color": GOOD},
	"narrow": {"text": "Narrow victory", "icon": "narrow_victory", "color": CAUTION},
	"loss": {"text": "Loss", "icon": "loss", "color": BAD},
}


static func ether(element) -> Color:
	return ETHER.get(element, LINE_SOFT) if element != null else LINE_SOFT


## A shade of an Ether for one job: base (the hue), deep (field centre and shadow),
## lit (highlights and glow), plate (an enhanced action's fill) or plate_ink (the
## ink with the most contrast on that plate).
static func ether_shade(element, role: String) -> Color:
	var base := ether(element)
	match role:
		"deep":
			return base.darkened(0.55)
		"lit":
			return base.lightened(0.35)
		"plate":
			return base.darkened(0.1) if element == "lightning" else base
		"plate_ink":
			var plate := ether_shade(element, "plate")
			return INK if ratio(INK, plate) >= ratio(BG_BASE, plate) else BG_BASE
	return base


## An accent colour as an edge or a fill: desaturated and stepped toward BG_RAISED.
static func muted(c: Color) -> Color:
	var grey := Color(c.get_luminance(), c.get_luminance(), c.get_luminance(), c.a)
	return c.lerp(grey, 0.25).lerp(Color(BG_RAISED, c.a), ACCENT_MUTE)


## An Ether as text or an icon on the dark panels: its lit shade, which keeps 3:1.
static func ether_ink(element) -> Color:
	return ether_shade(element, "lit")


## Relative luminance of a colour, as WCAG 2.1 defines it.
static func luminance(c: Color) -> float:
	var ch := func(v: float) -> float:
		return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch.call(c.r) + 0.7152 * ch.call(c.g) + 0.0722 * ch.call(c.b)


## WCAG contrast ratio between two colours, from 1 to 21.
static func ratio(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)
