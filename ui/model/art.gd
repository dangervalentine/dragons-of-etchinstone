extends RefCounted
## Which silhouette from art/creatures/ shows each Encounter and dragon, all made for
## this project (art/STYLE_PROMPT.md, art/creatures/CREDITS.md); the enemies follow
## the creatures on the official cards.

const ENEMIES := {
	1: ["panda-fighter", "lion-archer", "crane-monk", "monkey-brawler"],
	2: ["marsh-treant", "axe-gnome", "club-ogre", "horned-goblin"],
	3: ["twin-ghoul", "twin-ogre", "naga", "boar-shaman"],
	4: ["goblin-hexer", "hedge-wizard", "antler-horror", "gath-brute"],
}
const JOURNEYS := {
	1: ["peaks", "waterfall", "mountain-road", "cave-entrance"],
	2: ["swamp", "river", "willow-tree", "cliff-crossing"],
	3: ["volcano", "desert", "lava", "underground-cave"],
	4: ["rope-bridge", "forest-entrance", "burning-forest", "stone-path"],
}
## The road of the Final Journey, with the dragon waiting at its end.
const FINAL_JOURNEY := "horizon-road"
## Names for the Encounters, which the cards only number. These are this
## project's own, chosen to match the pictures; they are not from the game.
const ENEMY_NAMES := {
	1: ["Shaolin Panda", "Lionel Archer", "Crane Monk", "Frenzied Ape"],
	2: ["Swamp Treant", "Rapid Gnome", "Bog Ogre", "Goblin Raider"],
	3: ["Conjoined Ghoul", "Twin Ogre", "Naga Goro", "Wereboar"],
	4: ["Goblin Hexer", "Hedge Wizard", "Antlered Horror", "Brute of Gath"],
}
const JOURNEY_NAMES := {
	1: ["High Peaks", "The Falls", "Mountain Road", "Dark Cave"],
	2: ["Sunken Mire", "Black River", "Weeping Willows", "Cliff Path"],
	3: ["Ash Slopes", "Glass Desert", "Lava Fields", "Deep Caverns"],
	4: ["Rope Bridge", "Forest Gate", "Burning Wood", "Old Stone Stair"],
}
## Each dragon's full-body art, made for this project (art/STYLE_PROMPT.md).
const DRAGONS := {
	"grimroch": "grimroch", "helsang": "helsang",
	"rodving": "rodving", "vuurhast": "vuurhast",
}
## The whole of a piece of art, in its 512 units.
const FULL := Rect2(0, 0, 512, 512)
## Where each dragon's head is in its art, square, for the places that face it.
const HEADS := {
	"grimroch": Rect2(300, 88, 172, 172),
	"helsang": Rect2(292, 4, 174, 174),
	"rodving": Rect2(278, 6, 160, 160),
	"vuurhast": Rect2(284, 0, 178, 178),
}
## The same in each dragon's painted picture (art/painted/), drawn to its own
## composition: centred on its face, eye to snout, and from the top of its crest,
## antlers, horns or flames, so nothing of it rises past where the head is put.
const PAINTED_HEADS := {
	"grimroch": Rect2(226, 48, 160, 160),
	"helsang": Rect2(315, 40, 160, 160),
	"rodving": Rect2(228, 55, 145, 145),
	"vuurhast": Rect2(279, 40, 130, 130),
}
## Where the whole of each dragon lies in its art, the box round all it draws, for
## the places that frame it whole (the Dragon Card).
const BODIES := {
	"grimroch": Rect2(41, 29, 420, 463),
	"helsang": Rect2(50, 21, 384, 469),
	"rodving": Rect2(45, 24, 383, 448),
	"vuurhast": Rect2(64, 4, 358, 486),
}
## The same in each dragon's painted picture: one box for all four, the Dragon Card's
## room under its figures, so a dragon is drawn on the card where it is placed on its
## artboard (tools/dragon_template.svg draws the card round it: its
## edge, the ladders over the dragon, and the feet on 490).
const PAINTED_BODY := Rect2(41.1, 10, 429.7, 480)


## How each silhouette idles; see ui/fx/shaders/creature_idle.gdshader.
## breathe: heavy creatures that stand. hover: flyers and floaters. sway: rooted
## things and long necks. wave: bodies that ripple. shimmer: heat. flow: water.
## glow: still places, which only brighten and dim.
const MOTION := {
	# Dragons
	"grimroch": "breathe", "helsang": "breathe", "rodving": "breathe", "vuurhast": "breathe",
	# Region 1
	"panda-fighter": "breathe", "monkey-brawler": "breathe", "crane-monk": "breathe", "lion-archer": "breathe",
	"peaks": "glow", "waterfall": "flow", "mountain-road": "glow", "cave-entrance": "glow",
	# Region 2
	"axe-gnome": "breathe", "club-ogre": "breathe", "horned-goblin": "breathe", "marsh-treant": "sway",
	"swamp": "flow", "river": "flow", "willow-tree": "sway", "cliff-crossing": "glow",
	# Region 3
	"naga": "sway", "twin-ogre": "breathe", "twin-ghoul": "sway", "boar-shaman": "breathe",
	"volcano": "shimmer", "desert": "shimmer", "lava": "shimmer", "underground-cave": "glow",
	# Region 4
	"hedge-wizard": "breathe", "goblin-hexer": "breathe", "antler-horror": "sway", "gath-brute": "breathe",
	"rope-bridge": "hover", "forest-entrance": "sway", "burning-forest": "shimmer", "stone-path": "glow",
	# The Final Journey
	"horizon-road": "glow",
}
## Slow, heavy things move slower; small, quick ones faster.
const SPEED := {
	"grimroch": 0.6, "club-ogre": 0.7, "twin-ogre": 0.65, "gath-brute": 0.55,
	"marsh-treant": 0.7, "monkey-brawler": 0.8, "twin-ghoul": 0.8, "hedge-wizard": 0.85,
	"axe-gnome": 1.3, "horned-goblin": 1.2, "goblin-hexer": 1.1, "rope-bridge": 0.6,
}
## Silhouettes drawn in layers (tools/split_rig.py makes <name>-rig-<part>.svg and
## <name>-rig.json from <name>-parts.svg): the body, and the head and its jaw, each
## turning on its own. The json holds each part's pivot, its parent, the order they
## are drawn in, and the points marked on the art. Here is how each part moves; a
## part not named holds still. hinge: opens now and then and closes again, as the
## jaws do. swing: back and forth, evenly. rise: out to the angle and back to rest,
## smoothly, never past it. angle in degrees, clockwise when positive; period in
## the creature's time, scaled by its SPEED; phase shifts the cycle, in periods. A
## part turns about its own pivot, carried by its parent's turn. lunge, as well:
## now and then the part slides by shift (512 units) and back, as a hinge opens and
## closes, every period, carrying the parts it carries; a head thrust forward shows
## more of the neck behind it.
const RIGS := {
	"grimroch": {
		# Breathing runs a cycle every 4.19; the head lifts with it, counter-clockwise
		# about the eye, a little behind. Now and then it thrusts forward and the jaw
		# snaps, in the same cycle.
		"head": {"motion": "rise", "angle": -4.0, "period": 4.19, "phase": -0.1,
			"lunge": {"shift": Vector2(14, 4), "period": 6.0}},
		"jaw": {"motion": "hinge", "angle": 16.0, "period": 6.0},
	},
	"rodving": {
		"head": {"motion": "rise", "angle": -4.0, "period": 4.19, "phase": -0.1,
			"lunge": {"shift": Vector2(16, 6), "period": 6.0}},
		"jaw": {"motion": "hinge", "angle": 18.0, "period": 6.0},
	},
	"helsang": {
		"head": {"motion": "rise", "angle": -4.0, "period": 4.19, "phase": -0.1,
			"lunge": {"shift": Vector2(16, 6), "period": 6.0}},
		"jaw": {"motion": "hinge", "angle": 14.0, "period": 6.0},
	},
	"vuurhast": {
		"head": {"motion": "rise", "angle": -4.0, "period": 4.19, "phase": -0.1},
		# Opens as the neck lunges (BONES), in the same cycle.
		"jaw": {"motion": "hinge", "angle": 18.0, "period": 6.0},
	},
}
## Silhouettes bent in place by soft bones, with nothing cut out: each bone turns
## the art near the line from its joint to its tip about the joint, fully within
## three quarters of its reach of that line and fading out at its reach (512 units). joint and
## tip are points in 512 units, or the names of points marked on the art (in
## <name>-rig.json). Motions are as in RIGS, and one more, lunge: slides the art by
## shift (512 units) and back, as a hinge opens and closes, more the further along
## the bone, so what lies between joint and tip stretches. Bones that share a chain
## name, listed together from root to tip, are a chain: each carries the ones after
## it, as a tail's root swings all of it. A bone listed after another rides on it.
const BONES := {
	"vuurhast": [
		{"joint": Vector2(345, 300), "tip": Vector2(325, 110), "reach": 45.0, "motion": "swing", "angle": 2.0, "period": 8.38},
		# Now and then the neck thrusts the head forward, the jaw snapping with it.
		{"joint": Vector2(360, 300), "tip": Vector2(330, 80), "reach": 120.0, "motion": "lunge", "shift": Vector2(30, 8), "period": 6.0},
		# The tail whips: five bones from the hip around the curl to the tip, each
		# swinging a little behind the one before.
		{"chain": "tail", "joint": Vector2(215, 415), "tip": Vector2(130, 395), "reach": 50.0, "motion": "swing", "angle": 3.0, "period": 7.0},
		{"chain": "tail", "joint": Vector2(130, 395), "tip": Vector2(128, 300), "reach": 65.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.07},
		{"chain": "tail", "joint": Vector2(128, 300), "tip": Vector2(142, 190), "reach": 70.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.14},
		{"chain": "tail", "joint": Vector2(142, 190), "tip": Vector2(110, 128), "reach": 70.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.21},
		{"chain": "tail", "joint": Vector2(110, 128), "tip": Vector2(66, 152), "reach": 70.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.28},
	],
	# The arms hang heavy and drift at half the breath, against each other.
	"grimroch": [
		{"joint": "front-arm-joint", "tip": Vector2(285, 400), "reach": 30.0, "motion": "swing", "angle": 4.5, "period": 8.38},
		{"joint": "back-arm-joint", "tip": Vector2(365, 400), "reach": 30.0, "motion": "swing", "angle": 4.5, "period": 8.38, "phase": 0.5},
		# A short, heavy tail, lashing from the hip.
		{"chain": "tail", "joint": Vector2(170, 420), "tip": Vector2(110, 395), "reach": 38.0, "motion": "swing", "angle": 3.0, "period": 7.0},
		{"chain": "tail", "joint": Vector2(110, 395), "tip": Vector2(70, 370), "reach": 42.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.08},
		{"chain": "tail", "joint": Vector2(70, 370), "tip": Vector2(46, 343), "reach": 42.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.16},
	],
	"rodving": [
		{"joint": "front-arm-joint", "tip": Vector2(390, 330), "reach": 40.0, "motion": "swing", "angle": 4.5, "period": 8.38},
		{"joint": "back-arm-joint", "tip": Vector2(380, 295), "reach": 30.0, "motion": "swing", "angle": 4.5, "period": 8.38, "phase": 0.5},
	],
	"helsang": [
		{"joint": "front-arm-joint", "tip": Vector2(307, 400), "reach": 25.0, "motion": "swing", "angle": 4.5, "period": 8.38},
		{"joint": "back-arm-joint", "tip": Vector2(367, 413), "reach": 25.0, "motion": "swing", "angle": 4.5, "period": 8.38, "phase": 0.5},
		# The frilled tail curls down and round; its curl kept clear of the hind feet.
		{"chain": "tail", "joint": Vector2(225, 285), "tip": Vector2(165, 330), "reach": 40.0, "motion": "swing", "angle": 3.0, "period": 7.0},
		{"chain": "tail", "joint": Vector2(165, 330), "tip": Vector2(110, 385), "reach": 45.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.07},
		{"chain": "tail", "joint": Vector2(110, 385), "tip": Vector2(95, 440), "reach": 45.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.14},
		{"chain": "tail", "joint": Vector2(95, 440), "tip": Vector2(155, 420), "reach": 35.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.21},
	],
}
## The ways a part can move, as the shader numbers them.
const MOVES := {"still": 0, "hinge": 1, "swing": 2, "rise": 3, "lunge": 4}
static var _rigs := {}


static func motion(name: String) -> String:
	return MOTION.get(name, "still")


static func speed(name: String) -> float:
	return SPEED.get(name, 1.0)


## The layers a silhouette is drawn from, bottom first, or [] when it is all one
## piece. Each is {art, pivot (512 units), parent (an index into the list, or -1),
## motion, angle, period, phase}.
static func layers(name: String) -> Array:
	if RIGS.has(name):
		if not _rigs.has(name):
			_rigs[name] = _load_rig(name)
		return _rigs[name]
	return []


## The soft bones a silhouette bends by, or []: each as in BONES, its joint and tip
## as points in 512 units, and last, the index of the last bone it carries (itself,
## or the tip of its chain).
static func bones(name: String) -> Array:
	var list: Array = BONES.get(name, [])
	var out := []
	for i in list.size():
		var bone: Dictionary = list[i].duplicate()
		bone.joint = _point(name, bone.joint)
		bone.tip = _point(name, bone.tip)
		bone.last = i
		var chain: String = bone.get("chain", "")
		while chain != "" and bone.last + 1 < list.size() and list[bone.last + 1].get("chain", "") == chain:
			bone.last += 1
		out.append(bone)
	return out


## A point, or the point marked on the art by that name.
static func _point(name: String, at: Variant) -> Vector2:
	if at is Vector2:
		return at
	var p: Array = _rig_data(name).get("points", {}).get(at, [])
	assert(p.size() == 2, "%s has no point %s" % [name, at])
	return Vector2(p[0], p[1]) if p.size() == 2 else Vector2.ZERO


static func _rig_data(name: String) -> Dictionary:
	var path := "res://art/creatures/%s-rig.json" % name
	if not FileAccess.file_exists(path):
		return {}
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func _load_rig(name: String) -> Array:
	var data: Dictionary = _rig_data(name)
	var names: Array = data.layers.map(func(l): return l.name)
	var out := []
	for l in data.layers:
		var pivot: Vector2 = Vector2(l.pivot[0], l.pivot[1]) if l.pivot != null else Vector2.ZERO
		var parent: int = names.find(l.parent) if l.parent != null else -1
		out.append(_layer(l.art, pivot, parent, RIGS[name].get(l.name, {})))
	return out


static func _layer(art: String, pivot: Vector2, parent: int, move: Dictionary) -> Dictionary:
	return {
		"art": art, "pivot": pivot, "parent": parent,
		"motion": move.get("motion", "still"), "angle": move.get("angle", 0.0),
		"period": move.get("period", 1.0), "phase": move.get("phase", 0.0),
		"lunge": move.get("lunge", {}),
	}


## kind is "enemy" or "journey"; index is 1 to 4.
static func encounter(region: int, kind: String, index: int) -> String:
	var table: Dictionary = ENEMIES if kind == "enemy" else JOURNEYS
	return table[region][index - 1]


static func encounter_name(region: int, kind: String, index: int) -> String:
	var table: Dictionary = ENEMY_NAMES if kind == "enemy" else JOURNEY_NAMES
	return table[region][index - 1]


static func dragon(id: String) -> String:
	return DRAGONS.get(id, "")


## The region of `name` to show where the dragon is faced: its head, or all of it;
## in its painted picture when that is what is drawn (`painted`, UI.is_painted()).
static func head(name: String, painted := false) -> Rect2:
	if painted and PAINTED_HEADS.has(name):
		return PAINTED_HEADS[name]
	return HEADS.get(name, FULL)


## The region of `name` its whole body fills, or all of it where none is marked.
static func body(name: String, painted := false) -> Rect2:
	if painted and DRAGONS.values().has(name):
		return PAINTED_BODY
	return BODIES.get(name, FULL)


## The art to cut the head from: the head alone where the silhouette is drawn in
## layers (tools/split_rig.py), so none of the body behind it shows, or the whole.
static func head_art(name: String) -> String:
	var alone := name + "-rig-head-whole"
	return alone if ResourceLoader.exists("res://art/creatures/%s.svg" % alone) else name
