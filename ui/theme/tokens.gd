extends RefCounted
## The game's visual language: every size, colour, typeface and duration.
## Sizes are design units: one pixel of the 1280 x 720 landscape layout, about
## half a point on a phone held sideways. Widgets take their values from here.
##
## The values follow the "Inkstone and Brass" design system (specs/019): its
## tokens.json is the source of truth, and test_design_tokens holds this file to it.
## Its sizes are phone points; each is multiplied by 1.85 and rounded here (research
## R2), the system's own factor for a 720-unit-tall layout.

# Space (specs/019 research R2)
## Icon to number, numeral pill padding.
const SPACE_1 := 7
## Between cards in a set, chip padding, label to content.
const SPACE_2 := 15
## Inside panels and buttons; between buttons.
const SPACE_3 := 22
## The screen gutter inside the safe area; between the Encounter card and the tray.
const SPACE_4 := 30
## Between panel sections; banner padding.
const SPACE_5 := 44
## Between major regions of a screen (rare in landscape).
const SPACE_6 := 59
## Corner cuts for everything carved: chips, tabs and wells; buttons and panels; the
## tray, dialogs and banners. Only paper is rounded.
const CHAMFER_SM := 11
const CHAMFER_MD := 19
const CHAMFER_LG := 30
## A card's corner as a share of its width (8pt on the system's 100pt card), so
## every card of any size is cut alike.
const CARD_RADIUS_SHARE := 0.08
## Stat plates and numeral pills on cards.
const RADIUS_PLATE := 7
## Stone is etched: a light line inside the top edge, the edge line of panels and
## controls, and the brass (or jade) line of a selected, target or focused thing.
const BORDER_ETCH := 2
const BORDER_EDGE := 4
const BORDER_SELECT := 6
## The top bar inside the safe area, the bottom action row, a counter chip.
const TOPBAR_H := 74
const ACTION_H := 89
const CHIP_H := 52
## The widest a coach tip's paper gets: within the system's 340pt (629) maximum, at
## the width the lessons' messages were placed for, so a message never covers what
## it lights (about 50 characters a line); and a dialog.
const COACH_MAX_W := 560.0
const DIALOG_W := 666
## Nothing interactive is smaller than this on its shorter side. Larger than the
## system's touch-min (81) on purpose: it was the game's floor before (research R2).
const TAP_MIN := 88
## Nothing that has to be read is set smaller than this: the system's caption.
const TEXT_MIN := 22
## Text printed on a card laid on the Deck (a note) may be set this small, as it
## shrinks to fit its card (owner, 2026-10-22: "relax the font size restriction").
const CARD_TEXT_MIN := 18
## The least side of something pressed only to explain it (a figure's chip).
const HELP_MIN := 44
## Card names alone may go this small (the system's card-name), so the longest
## name still fits two lines on the narrowest card (specs/019 FR-015).
const CARD_NAME_MIN := 20
## A Mage Card's width at the design system's size (card-width, 100pt).
const CARD_W := 185
## The card-name floor as a share of the card's width (card_face.gd name_floor): 18
## on the narrowest phone's 220-wide card, the most the longest name fits beside the
## Ether glyph; one step under CARD_NAME_MIN (owner, 2026-10-22).
const CARD_NAME_SHARE := 18.0 / 220.0

# Type (specs/019 contracts/type-styles.md)
# Display is Fraunces (variable: weight, optical size, SOFT 50, WONK 0) for banners,
# titles, headings, card names and every figure. Sans is Alegreya Sans for labels,
# buttons and everything read as text. upper: the style sets its text in capitals.
## Region banner, the verdict, the game's name. One per screen.
const BANNER := {"family": "display", "size": 63, "weight": 800, "opsz": 72, "spacing": 0.01, "upper": true}
## The top bar's heading, dialog and screen titles. Title case.
const TITLE := {"family": "display", "size": 41, "weight": 700, "opsz": 36, "spacing": 0.01, "upper": false}
## Panel heads, Encounter names, dragon names.
const HEADING := {"family": "display", "size": 31, "weight": 700, "opsz": 24, "spacing": 0.0, "upper": false}
## Mage Card names, fitted to their band but never below CARD_NAME_MIN.
const CARD_NAME := {"family": "display", "size": 20, "weight": 700, "opsz": 12, "spacing": 0.03, "upper": true}
## Score, a Key Card's Level, the Dragon's HP.
const NUMERAL_XL := {"family": "display", "size": 67, "weight": 900, "opsz": 72, "spacing": 0.0, "upper": false}
## Card figures, Result sums, Enemy stat shapes.
const NUMERAL := {"family": "display", "size": 37, "weight": 800, "opsz": 24, "spacing": 0.0, "upper": false}
## Counters, a card's cost and XP, chips.
const NUMERAL_SM := {"family": "display", "size": 26, "weight": 800, "opsz": 14, "spacing": 0.0, "upper": false}
## Slot headers, column heads, kickers: muted at rest, brass on the target.
const LABEL := {"family": "sans", "size": 22, "weight": 800, "spacing": 0.1, "upper": true}
## Every button's words. Sentence case.
const BUTTON := {"family": "sans", "size": 30, "weight": 800, "spacing": 0.01, "upper": false}
## Panel copy, coach tips, rulebook paragraphs.
const BODY := {"family": "sans", "size": 28, "weight": 500, "spacing": 0.0, "upper": false}
## Encounter effect text, table rows, secondary panel copy.
const BODY_SM := {"family": "sans", "size": 24, "weight": 500, "spacing": 0.0, "upper": false}
## Hints and fine print: the smallest live text.
const CAPTION := {"family": "sans", "size": 22, "weight": 500, "spacing": 0.0, "upper": false}
## Extends the design system (specs/019 R12): bold words in running text (a verdict,
## an outcome, a term in a paragraph), at the body size unless restyled.
const BODY_STRONG := {"family": "sans", "size": 28, "weight": 700, "spacing": 0.0, "upper": false}
## Every style, by name, for the checks.
const STYLES := ["BANNER", "TITLE", "HEADING", "CARD_NAME", "NUMERAL_XL", "NUMERAL",
	"NUMERAL_SM", "LABEL", "BUTTON", "BODY", "BODY_SM", "CAPTION"]

# Colour (specs/019 contracts/tokens.md). The art is the colour: the chrome stays in
# low-chroma stone, and brass means "here".
## The table: the ground behind everything, washed with the Region's tint in play.
const GROUND := Color("0e1517")
## Panels, trays, the top bar, dialogs, banners.
const STONE := Color("172225")
## Buttons, tabs, chips you press: the slab you can press.
const STONE_RAISED := Color("213033")
## Sunken slots and wells, always with an inset shadow.
const WELL := Color("0a1012")
## Hairline dividers and disabled rims; never a border that means something.
const LINE := Color("2e3f40")
## The etched rim of panels and controls: 3.5:1 on stone, 4:1 on the ground.
const EDGE := Color("64797a")
## All primary text and icons on stone; the step-emphasis ring (research R6).
const PARCHMENT := Color("f1e3d1")
## Secondary text, column heads, inactive tabs.
const PARCHMENT_MUTED := Color("b4a894")
## Disabled labels only: deliberately below 4.5:1.
const PARCHMENT_FAINT := Color("5f675f")
## The primary action's fill, the selected rim, the target slot. Nothing else.
const BRASS := Color("dcb35c")
## Rewards: Score, XP, the star, 1st place, banner headlines.
const BRASS_BRIGHT := Color("f2d16b")
## A brass button's bevel and edge; a glossary term's underline on paper.
const BRASS_DEEP := Color("8a6a2c")
## Ink on brass, bright brass and ochre. Never white on brass.
const ON_BRASS := Color("1c1508")
## Good outcomes and the keyboard focus ring, always with a tick or icon.
const JADE := Color("8fc4a3")
## Harm, always with a minus sign, heart or skull.
const DANGER := Color("ee7a62")
## The HP heart.
const STAT_HP := Color("e2697a")
## Reading surfaces: coach tips, the glossary, rulebook pages, the XP question.
const PAPER := Color("e9dac4")
const PAPER_INK := Color("1b2324")
const PAPER_MUTED := Color("5a5244")
## Behind dialogs, the glossary, the menu, banners and the coach mark's dim.
const SCRIM := Color(5.0 / 255.0, 9.0 / 255.0, 10.0 / 255.0, 0.82)
## The frame and title band of every Mage, Key and Encounter card; the top bar's foot.
const CARD_FRAME := Color("121618")
## A card's stat ribbon (cost, XP) and the Key Card strip: leather between brass and stone.
const CARD_RIBBON := Color("6b5639")
## The dark plates behind card figures, and the ink on a highlighted figure's pill.
const STAT_PLATE := Color("101314")
## The Ethers' mineral pigments and their bright partners (the highlighted figure).
## The glyph tells them apart first: lapis, amethyst and cinnabar sit close in lightness.
const ETHER := {
	"water": {"base": Color("3566b0"), "bright": Color("5a8bdb")},
	"lightning": {"base": Color("c9902c"), "bright": Color("e8b245")},
	"shadow": {"base": Color("7350b0"), "bright": Color("9576dd")},
	"fire": {"base": Color("b93a2e"), "bright": Color("de5a44")},
}
## Which character the card field shader draws for each Ether.
const ETHER_ID := {"fire": 0, "water": 1, "lightning": 2, "shadow": 3}
## Each Region's own colour, a hue apart from the others: the glow on the ground, the
## banner's rim and medallion. Slate, teal, burnt copper, green.
const REGION := {1: Color("7f8e95"), 2: Color("3f8f88"), 3: Color("b8703a"), 4: Color("4f8a4a")}
## A won game's ending.
const REGION_LAIR := Color("8a3b3a")
## The whole ground in each Region: GROUND steeped in the Region's hue, so each leg of
## the journey stands on its own country. Dark enough that text and edges keep their
## contrast on it (test_palette_contrast).
const REGION_GROUND := {1: Color("13181b"), 2: Color("0a1a1a"), 3: Color("20140b"), 4: Color("0d1a0e")}
## The Final Battle's ground, by the dragon's Ether, under a glow of that Ether's base.
const LAIR_GROUND := {"water": Color("0c1426"), "lightning": Color("1e170a"), "shadow": Color("170f25"), "fire": Color("220c0b")}
## Extends the design system (specs/019 R12): the colours of things the system does
## not name. Sword blades and metal glyphs; the time-penalty chip's glass; a locked
## dragon's silhouette; an unchosen dragon dimmed and hovered; the Deck's back.
const METAL := Color("8f9a9a")
const GLASS := Color("3a4a4c")
## The time-penalty chip on an Encounter's face and the Region Card: lighter steel,
## and its glass.
const METAL_LIGHT := Color("a8b1b0")
const GLASS_LIGHT := Color("707b7a")
const LOCKED := Color(10.0 / 255.0, 16.0 / 255.0, 18.0 / 255.0, 0.9)
const DIM_MODULATE := Color(0.5, 0.52, 0.52)
const DIM_HOVER := Color(0.78, 0.8, 0.8)
const DECK_BACK := Color(16.0 / 255.0, 22.0 / 255.0, 24.0 / 255.0, 0.88)
## Black and white, taken at an alpha for shades and sheens (shadows, bevels, hover).
const SHADE := Color(0, 0, 0)
const SHEEN := Color(1, 1, 1)
## The hard drop of a slab or card onto the table.
## Extends the design system (specs/019 R12): the colour its shadows are written in.
const SHADOW_DROP := Color("070b0c")

# Depth (specs/019 contracts/tokens.md): a carved slab, pressed, a brass button, a
# sunken well, a card on the table and a card held up. Widths in design units.
const SHADOW_SLAB := {"etch": 2, "etch_colour": Color(PARCHMENT, 0.10), "bevel": 6, "bevel_colour": Color(0, 0, 0, 0.35), "drop": 6}
const SHADOW_SLAB_PRESSED := {"inset": 4, "inset_colour": Color(0, 0, 0, 0.45), "drop": 2}
const SHADOW_BRASS := {"etch": 2, "etch_colour": Color(1.0, 244.0 / 255.0, 214.0 / 255.0, 0.55), "bevel": 6, "bevel_colour": BRASS_DEEP, "drop": 6}
const SHADOW_WELL := {"offset": 4, "blur": 11, "colour": Color(0, 0, 0, 0.6)}
const SHADOW_CARD := {"drop": 4, "offset": 15, "blur": 33, "colour": Color(0, 0, 0, 0.45)}
const SHADOW_LIFT := {"drop": 7, "offset": 30, "blur": 59, "colour": Color(0, 0, 0, 0.55)}
## The Region's glow over the ground.
const REGION_WASH := 0.22
## How strongly a Region's ground texture shades its ground: 0 flat, 1 the texture's
## full range (its mid grey leaves the ground as it is). Extends the design system.
const REGION_TEXTURE := 0.6
## A card out of play: fully grey, at this opacity.
const OUT_OF_PLAY := 0.45

const DISABLED_ALPHA := 0.45
## The leather ribbon's shade and its light, for its torn edge and its rule (card_face.gd).
const CARD_RIBBON_DARK := Color("453825")
const CARD_RIBBON_LIGHT := Color("9f917e")
## The Deck seen from the side (feature 014): each card's edge in card stock, and
## the line between one card and the next. Never an Ether's colour.
const CARD_EDGE := Color("8d8778")
const CARD_EDGE_LINE := Color("4a463e")

# Layout
## The layout solver's own gutter round the screen and gap between the action row's
## buttons. They stay at their old sizes, not the design system's space scale: the
## solver keeps the large geometry, and the cards are what it spends room on (specs/019
## research R2; the system's card-width, 185 units, is larger than today's cards).
const LAYOUT_GUTTER := 16
const LAYOUT_GAP := 8
## The margin the Deck's card edges take on the right and bottom of the left side.
const DECK_EDGE := 24
## The narrowest the left column gets (feature 013): it fixes the smallest whole
## Region Card, whose figures must still read at TEXT_MIN.
const LEFT_MIN_W := 400
## The least height of a note on the Deck that sets the result out line by line.
const NOTE_ROOMY_H := 360
## Every icon read in a note's content (a verdict, the damage, the XP, an Ether, a
## status), one size on every card.
const NOTE_ICON := 30
## A note's flight in from off the left of the screen to its place on the Deck, and
## its flight off to the left again as a discard (feature 015).
const NOTE_DEAL := 0.35
const NOTE_DISCARD := 0.35
## The lesson coach mark (feature 017, contracts/coach-mark.md): the screen round the
## lit part takes the SCRIM while a message is read; while the player acts, nothing
## is dimmed.
## The rim round the lit part: how far it stands off the target, and its width.
const COACH_PAD := 8.0
const COACH_RIM := 3.0
## The message bubble: its distance from the rim.
const COACH_GAP := 16.0
## The coach mark's fade in, when motion is not reduced.
const COACH_FADE := 0.2
## How far, in degrees, a note is turned off the table, as a dealt or thrown card is.
const NOTE_TURN := 14.0
## The tilt, in degrees, each note lies at by its depth under the top one, so the
## corners of those under it show; deeper ones repeat the last.
const NOTE_TILT := [0.0, -1.2, 0.9, -0.6]
## How much later each note under the top one leaves when the pile is thrown.
const NOTE_PILE_STAGGER := 0.04
## A step card turning over to its next step (a Fuse's), edge on half way.
const NOTE_FLIP := 0.36

# Creatures
## The ink line round a painted figure on its panel, so a creature painted in mid
## greys stands off a ground of much the same lightness: its colour, and its width
## as a share of the art's side, so it scales with the picture as printed ink would,
## but never thinner than CREATURE_LINE_MIN pixels on screen.
const CREATURE_LINE := Color("0b0910")
const CREATURE_LINE_SHARE := 0.009
const CREATURE_LINE_MIN := 1.5
## The light behind a figure on its panel, in its Ether's lit shade: how strong at
## its heart, and how far it reaches past the figure's box, as a share of its size.
const CREATURE_BACKLIGHT := 0.32
const CREATURE_BACKLIGHT_REACH := 0.35
## How far left of the panel's middle an Enemy stands, as a share of the art's width:
## centred, the figures came too far forward; set back a little they balance the scene.
const ENEMY_SET_BACK := 0.15

# Stone
## The edges of a carved bevel.
const BEVEL_LIGHT := Color(1, 1, 1, 0.10)
const BEVEL_SHADOW := Color(0, 0, 0, 0.45)

# Motion, in seconds
const INSTANT := 0.08
const FAST := 0.15
const BASE := 0.25
const MOVE := 0.35
const COUNT := 0.6
const REVEAL := 0.4
const STAGGER := 0.12
const SEQUENCE_MAX := 3.0
## A slab pressed in and let go, and how far it drops (2pt) (specs/019 FR-023).
const PRESS := 0.08
const RELEASE := 0.12
const PRESS_DROP := 4
## The Deck (feature 012): zooming between the top card and a face, turning the
## Region Card, and the Key Card rising from under it and, as the zoom starts,
## sliding back.
const ZOOM := 0.55
const TURN := 0.5
## The Deck riffled under the card on top whenever it is shuffled (feature 016),
## as NextQuest riffles its cards: up to SHUFFLE_PEELS Mage Cards peel out from
## under it one after another, each out and back in a share SHUFFLE_ARC of the
## time, out SHUFFLE_PEEL of the way a Key Card rises, tilted SHUFFLE_TILT degrees
## and shrunk to SHUFFLE_SCALE at the height of its arc.
const SHUFFLE := 0.9
const SHUFFLE_PEELS := 5
const SHUFFLE_ARC := 0.45
const SHUFFLE_PEEL := 0.6
const SHUFFLE_TILT := 2.0
const SHUFFLE_SCALE := 0.96
## The Soak's meter filling and the XP purse's bar draining as cards are chosen.
const FILL := 0.5
const PEEK_RISE := 0.25
const PEEK_FALL := 0.2
## A drawn card's flight from the top card, at its size, to its place in the Hand
## (feature 014).
const DRAW_FLY := 0.45
## A Time Penalty's cards leave the Deck for the Discard slower than a draw, one
## well after another, so each is seen to go; the whole penalty within PAY_MAX.
const PAY_FLY := 1.0
const PAY_STAGGER := 0.4
const PAY_MAX := 3.0
## Damage and XP move the same way: each mark or star flies slowly enough to be
## seen, one well after another, all of them within MOTE_MAX; damage's figure
## stays up as long.
const MOTE_FLY := 0.8
const MOTE_STAGGER := 0.25
const MOTE_MAX := 2.5
const DAMAGE := 1.0
## At most this many stars for XP won, one per XP up to it.
const XP_STARS := 10
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
	"complete": {"text": "Complete victory", "icon": "victory", "color": JADE},
	"narrow": {"text": "Narrow victory", "icon": "narrow_victory", "color": BRASS},
	"loss": {"text": "Loss", "icon": "loss", "color": DANGER},
}


## An Ether's pigment, or the etched edge for none.
static func ether(element) -> Color:
	return ETHER[element].base if element != null and ETHER.has(element) else EDGE


## A shade of an Ether for one job (specs/019 research R11):
## base: the pigment (a card's field, a wash);
## deep: the field's centre and its shadow;
## lit: its bright partner, for icons and text on stone;
## plate: an enhanced action's plate, and a highlighted basic action's pill;
## plate_ink: the ink on either;
## paper: an icon of it printed on paper (deep enough to read on the warm sheet).
static func ether_shade(element, role: String) -> Color:
	var base := ether(element)
	var bright: Color = ETHER[element].bright if element != null and ETHER.has(element) else PARCHMENT_MUTED
	match role:
		"deep":
			return base.darkened(0.55)
		"lit":
			return bright
		"plate":
			return base
		"plate_ink":
			return ON_BRASS if element == "lightning" else PARCHMENT
		"paper":
			return base.darkened(0.45 if element == "lightning" else 0.25)
	return base


## An Ether as text or an icon on the dark panels: its bright partner.
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
