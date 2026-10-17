extends RefCounted
## Which silhouette from art/creatures/ shows each Encounter and dragon, all made for
## this project (art/STYLE_PROMPT.md, art/creatures/CREDITS.md); the enemies follow
## the creatures on the official cards.

const ENEMIES := {
	1: ["panda-fighter", "monkey-brawler", "crane-monk", "lion-archer"],
	2: ["axe-gnome", "club-ogre", "horned-goblin", "marsh-treant"],
	3: ["naga", "twin-ogre", "twin-ghoul", "boar-shaman"],
	4: ["hedge-wizard", "goblin-hexer", "antler-horror", "gath-brute"],
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
	1: ["Shaolin Panda", "Frenzied Ape", "Crane Monk", "Lionel Archer"],
	2: ["Rapid Gnome", "Bog Ogre", "Goblin Raider", "Swamp Treant"],
	3: ["Naga Goro", "Twin Ogre", "Conjoined Ghoul", "Wereboar"],
	4: ["Hedge Wizard", "Goblin Hexer", "Antlered Horror", "Brute of Gath"],
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
## part turns about its own pivot, carried by its parent's turn.
const RIGS := {
	"grimroch": {
		# Breathing runs a cycle every 4.19; the head lifts with it, counter-clockwise
		# about the eye, a little behind.
		"head": {"motion": "rise", "angle": -4.0, "period": 4.19, "phase": -0.1},
		"jaw": {"motion": "hinge", "angle": 16.0, "period": 4.0},
	},
	"rodving": {
		"head": {"motion": "rise", "angle": -4.0, "period": 4.19, "phase": -0.1},
		"jaw": {"motion": "hinge", "angle": 18.0, "period": 3.4},
	},
	"helsang": {
		"head": {"motion": "rise", "angle": -4.0, "period": 4.19, "phase": -0.1},
		"jaw": {"motion": "hinge", "angle": 14.0, "period": 3.6},
	},
	"vuurhast": {
		"head": {"motion": "rise", "angle": -4.0, "period": 4.19, "phase": -0.1},
		"jaw": {"motion": "hinge", "angle": 14.0, "period": 3.2},
	},
}
## Silhouettes bent in place by soft bones, with nothing cut out: each bone turns
## the art near the line from its joint to its tip about the joint, fully within
## half its reach of that line and fading out at its reach (512 units). joint and
## tip are points in 512 units, or the names of points marked on the art (in
## <name>-rig.json). Motions are as in RIGS. A bone listed after another rides on it.
const BONES := {
	"vuurhast": [
		{"joint": Vector2(345, 300), "tip": Vector2(325, 110), "reach": 45.0, "motion": "swing", "angle": 2.0, "period": 8.38},
		{"joint": Vector2(150, 410), "tip": Vector2(75, 140), "reach": 40.0, "motion": "swing", "angle": 3.0, "period": 8.38, "phase": 0.25},
	],
	# The arms hang heavy and drift at half the breath, against each other.
	"grimroch": [
		{"joint": "front-arm-joint", "tip": Vector2(285, 400), "reach": 30.0, "motion": "swing", "angle": 4.5, "period": 8.38},
		{"joint": "back-arm-joint", "tip": Vector2(365, 400), "reach": 30.0, "motion": "swing", "angle": 4.5, "period": 8.38, "phase": 0.5},
	],
	"rodving": [
		{"joint": "front-arm-joint", "tip": Vector2(390, 330), "reach": 40.0, "motion": "swing", "angle": 4.5, "period": 8.38},
		{"joint": "back-arm-joint", "tip": Vector2(380, 295), "reach": 30.0, "motion": "swing", "angle": 4.5, "period": 8.38, "phase": 0.5},
	],
	"helsang": [
		{"joint": "front-arm-joint", "tip": Vector2(307, 400), "reach": 25.0, "motion": "swing", "angle": 4.5, "period": 8.38},
		{"joint": "back-arm-joint", "tip": Vector2(367, 413), "reach": 25.0, "motion": "swing", "angle": 4.5, "period": 8.38, "phase": 0.5},
	],
}
## The ways a part can move, as the shader numbers them.
const MOVES := {"still": 0, "hinge": 1, "swing": 2, "rise": 3}
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
## as points in 512 units.
static func bones(name: String) -> Array:
	var out := []
	for b in BONES.get(name, []):
		var bone: Dictionary = b.duplicate()
		bone.joint = _point(name, b.joint)
		bone.tip = _point(name, b.tip)
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


## The region of `name` to show where the dragon is faced: its head, or all of it.
static func head(name: String) -> Rect2:
	return HEADS.get(name, FULL)


## The art to cut the head from: the head alone where the silhouette is drawn in
## layers (tools/split_rig.py), so none of the body behind it shows, or the whole.
static func head_art(name: String) -> String:
	var alone := name + "-rig-head-whole"
	return alone if ResourceLoader.exists("res://art/creatures/%s.svg" % alone) else name
