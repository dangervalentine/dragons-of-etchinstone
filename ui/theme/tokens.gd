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
const ETHER := {
	"fire": Color("e2543a"), "water": Color("4a9cf0"),
	"lightning": Color("e8ad2a"), "shadow": Color("a56cf0"),
}
const DISABLED_ALPHA := 0.45

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
