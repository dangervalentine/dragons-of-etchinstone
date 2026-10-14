extends RefCounted
## Which silhouette from art/creatures/ shows each Encounter and dragon. The card
## data gives Encounters no names, so each was chosen to fit its Region, its Ether
## and its Ability. Sources and authors are listed in art/creatures/CREDITS.md.

const ENEMIES := {
	1: ["harpy", "salamander", "ice-golem", "troll"],
	2: ["lizardman", "eel", "toad-teeth", "spectre"],
	3: ["rock-golem", "tortoise", "scorpion", "vulture"],
	4: ["angular-spider", "goblin-head", "wolf-head", "evil-tree"],
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
	1: ["Crag Harpy", "Ember Salamander", "Ice Golem", "Mountain Troll"],
	2: ["Marsh Lizardman", "Thunder Eel", "Bog Toad", "Marsh Spectre"],
	3: ["Obsidian Golem", "Steam Tortoise", "Sand Scorpion", "Storm Vulture"],
	4: ["Shadow Spider", "Goblin Archer", "Thunder Wolf", "Rotwood Treant"],
}
const JOURNEY_NAMES := {
	1: ["High Peaks", "The Falls", "Mountain Road", "Dark Cave"],
	2: ["Sunken Mire", "Black River", "Weeping Willows", "Cliff Path"],
	3: ["Ash Slopes", "Glass Desert", "Lava Fields", "Deep Caverns"],
	4: ["Rope Bridge", "Forest Gate", "Burning Wood", "Old Stone Stair"],
}
const DRAGONS := {
	"grimroch": "spiked-dragon-head", "helsang": "dragon-head",
	"rodving": "sea-serpent", "vuurhast": "wyvern",
}


## How each silhouette idles; see ui/fx/shaders/creature_idle.gdshader.
## breathe: heavy creatures that stand. hover: flyers and floaters. sway: rooted
## things and long necks. wave: bodies that ripple. shimmer: heat. flow: water.
## glow: still places, which only brighten and dim.
const MOTION := {
	# Dragons
	"spiked-dragon-head": "breathe", "dragon-head": "hover", "sea-serpent": "sway", "wyvern": "hover",
	# Region 1
	"harpy": "hover", "salamander": "breathe", "ice-golem": "breathe", "troll": "breathe",
	"peaks": "glow", "waterfall": "flow", "mountain-road": "glow", "cave-entrance": "glow",
	# Region 2
	"lizardman": "breathe", "eel": "wave", "toad-teeth": "breathe", "spectre": "wave",
	"swamp": "flow", "river": "flow", "willow-tree": "sway", "cliff-crossing": "glow",
	# Region 3
	"rock-golem": "breathe", "tortoise": "breathe", "scorpion": "sway", "vulture": "hover",
	"volcano": "shimmer", "desert": "shimmer", "lava": "shimmer", "underground-cave": "glow",
	# Region 4
	"angular-spider": "hover", "goblin-head": "breathe", "wolf-head": "breathe", "evil-tree": "sway",
	"rope-bridge": "hover", "forest-entrance": "sway", "burning-forest": "shimmer", "stone-path": "glow",
	# The Final Journey
	"horizon-road": "glow",
}
## Slow, heavy things move slower; small, quick ones faster.
const SPEED := {
	"troll": 0.7, "rock-golem": 0.6, "ice-golem": 0.65, "tortoise": 0.55, "toad-teeth": 0.8,
	"spiked-dragon-head": 0.6, "evil-tree": 0.7, "harpy": 1.3, "vulture": 1.1, "angular-spider": 0.9,
	"eel": 1.2, "spectre": 0.8, "rope-bridge": 0.6,
}
## Silhouettes cut into a body (<name>-base.svg) and a part that moves on its own
## (<name>-part.svg), drawn together; <name>.svg stays whole for small uses. pivot is
## in the art's 512 units; angle in degrees, clockwise when positive. See
## art/STYLE_PROMPT.md for how they are made.
const PARTS := {
	"spiked-dragon-head": {"motion": "hinge", "pivot": Vector2(262, 305), "angle": 16.0, "period": 4.0},
	"dragon-head": {"motion": "hinge", "pivot": Vector2(330, 268), "angle": -14.0, "period": 3.6},
	"sea-serpent": {"motion": "hinge", "pivot": Vector2(234, 136), "angle": -10.0, "period": 3.2},
	"wyvern": {"motion": "hinge", "pivot": Vector2(252, 224), "angle": -11.0, "period": 4.4},
}


static func motion(name: String) -> String:
	return MOTION.get(name, "still")


static func speed(name: String) -> float:
	return SPEED.get(name, 1.0)


## The moving part of a silhouette, or {} when it is all one piece.
static func part(name: String) -> Dictionary:
	return PARTS.get(name, {})


## kind is "enemy" or "journey"; index is 1 to 4.
static func encounter(region: int, kind: String, index: int) -> String:
	var table: Dictionary = ENEMIES if kind == "enemy" else JOURNEYS
	return table[region][index - 1]


static func encounter_name(region: int, kind: String, index: int) -> String:
	var table: Dictionary = ENEMY_NAMES if kind == "enemy" else JOURNEY_NAMES
	return table[region][index - 1]


static func dragon(id: String) -> String:
	return DRAGONS.get(id, "")
