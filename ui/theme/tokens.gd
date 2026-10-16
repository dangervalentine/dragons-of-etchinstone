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
const TITLE := ["display_bold", 64]
const BANNER := ["display_bold", 46]
const HEADING := ["display", 30]
const CARD_NAME := ["display", 21]
const NUMERAL := ["display_bold", 32]
const NUMERAL_L := ["display_bold", 52]
const BODY := ["body", 26]
const LABEL := ["body_medium", 22]
const BUTTON := ["body_bold", 27]

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
## The near-black of a Mage Card's frame and bands.
const CARD_FRAME := Color("0d0b10")
## The Key Card strip under the name.
const BRONZE := Color("5a4632")
const BRONZE_DARK := Color("3a2c1f")
const BRONZE_LIGHT := Color("a88a63")

# Layout
## The least height a face needs at the 400-unit left column, with its content 4
## units clear of the edge (measured for feature 006, T009): a Region Enemy with four
## badge rows at their 52-unit minimum and the Key Card line (a Journey needs 206);
## the dragon's face with its tiers (332 on the Final Journey, 384 for Grimroch's
## Final Enemy).
const ENCOUNTER_MIN := 316
const DRAGON_MIN := 384
## The least height the preview takes in the left column; the Encounter gets the rest.
const PREVIEW_MIN := 150

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
