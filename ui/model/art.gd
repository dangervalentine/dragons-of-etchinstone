extends RefCounted
## Which painted picture from art/painted/ shows each Encounter and dragon, all made
## for this project (art/PAINTED_PROMPTS.txt, art/creatures/CREDITS.md); the enemies
## follow the creatures on the official cards. Journeys are maps in
## art/painted/journeys/. The Final Journey's road is the one silhouette still drawn,
## from art/creatures/.

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
## Each dragon's art, made for this project (art/PAINTED_PROMPTS.txt).
const DRAGONS := {
	"grimroch": "grimroch", "helsang": "helsang",
	"rodving": "rodving", "vuurhast": "vuurhast",
}
## The whole of a piece of art, in its 512 units.
const FULL := Rect2(0, 0, 512, 512)
## Where each dragon's head is in its painted picture, drawn to its own
## composition: centred on its face, eye to snout, and from the top of its crest,
## antlers, horns or flames, so nothing of it rises past where the head is put.
const HEADS := {
	"grimroch": Rect2(226, 48, 160, 160),
	"helsang": Rect2(315, 40, 160, 160),
	"rodving": Rect2(228, 55, 145, 145),
	"vuurhast": Rect2(279, 40, 130, 130),
}
## Where the whole of each dragon lies in its painted picture: one box for all four,
## the Dragon Card's room under its figures, so a dragon is drawn on the card where it
## is placed on its artboard (tools/dragon_template.svg draws the card round it: its
## edge, the ladders over the dragon, and the feet on 490).
const BODY := Rect2(41.1, 10, 429.7, 480)


## How each picture idles; see ui/fx/shaders/creature_idle.gdshader.
## breathe: heavy creatures that stand. sway: rooted things and long necks.
## glow: still places, which only brighten and dim.
const MOTION := {
	# Dragons
	"grimroch": "breathe", "helsang": "breathe", "rodving": "breathe", "vuurhast": "breathe",
	# Region 1
	"panda-fighter": "breathe", "monkey-brawler": "breathe", "crane-monk": "breathe", "lion-archer": "breathe",
	# Region 2
	"axe-gnome": "breathe", "club-ogre": "breathe", "horned-goblin": "breathe", "marsh-treant": "sway",
	# Region 3
	"naga": "sway", "twin-ogre": "breathe", "twin-ghoul": "sway", "boar-shaman": "breathe",
	# Region 4
	"hedge-wizard": "breathe", "goblin-hexer": "breathe", "antler-horror": "sway", "gath-brute": "breathe",
	# The Final Journey
	"horizon-road": "glow",
}
## Slow, heavy things move slower; small, quick ones faster.
const SPEED := {
	"grimroch": 0.6, "club-ogre": 0.7, "twin-ogre": 0.65, "gath-brute": 0.55,
	"marsh-treant": 0.7, "monkey-brawler": 0.8, "twin-ghoul": 0.8, "hedge-wizard": 0.85,
	"axe-gnome": 1.3, "horned-goblin": 1.2, "goblin-hexer": 1.1,
}
## Soft bones bend each picture in place: each bone turns the art near the line
## from its joint to its tip about the joint, fully within three quarters of its
## reach of that line and fading out at its reach. joint, tip and reach are in 512
## units, measured on the picture's own composition. swing: back and forth, evenly.
## rise: out to the angle and back to rest, smoothly, never past it. still: holds,
## only widening what its chain carries. angle in degrees, clockwise when positive;
## period in the creature's time, scaled by its SPEED; phase shifts the cycle, in
## periods. Bones that share a chain name, listed together from root to tip, are a
## chain: each carries the ones after it, as a tail's root swings all of it. A bone
## listed after another rides on it. The head lifts with the breath; the bones
## after it in its chain hold still and only widen what it carries (antlers, horns,
## flames, breath). Only parts with open ground around them move; a tail cut off at
## the picture's edge moves only near the hip, or not at all.
const BONES := {
	"grimroch": [
		# The near arm hangs over the belly, so it drifts less than the free one.
		{"joint": Vector2(100, 262), "tip": Vector2(172, 405), "reach": 24.0, "motion": "swing", "angle": 2.5, "period": 8.38},
		{"joint": Vector2(258, 215), "tip": Vector2(290, 400), "reach": 30.0, "motion": "swing", "angle": 4.0, "period": 8.38, "phase": 0.5},
		{"chain": "head", "joint": Vector2(255, 150), "tip": Vector2(362, 162), "reach": 48.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(265, 150), "tip": Vector2(278, 62), "reach": 34.0, "motion": "still"},
	],
	"helsang": [
		# The wing beats slowly with the breath: the leading edge and the membrane
		# below it turn together about the shoulder.
		{"chain": "wing", "joint": Vector2(210, 255), "tip": Vector2(40, 180), "reach": 70.0, "motion": "swing", "angle": 2.5, "period": 4.19},
		{"chain": "wing", "joint": Vector2(210, 255), "tip": Vector2(90, 270), "reach": 40.0, "motion": "still"},
		{"chain": "wing", "joint": Vector2(210, 255), "tip": Vector2(218, 130), "reach": 40.0, "motion": "still"},
		{"joint": Vector2(275, 330), "tip": Vector2(305, 440), "reach": 22.0, "motion": "swing", "angle": 4.0, "period": 8.38},
		# The tail runs off the edge, so only its root swings.
		{"joint": Vector2(150, 345), "tip": Vector2(90, 410), "reach": 32.0, "motion": "swing", "angle": 2.5, "period": 7.0},
		{"chain": "head", "joint": Vector2(300, 205), "tip": Vector2(375, 210), "reach": 40.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(300, 205), "tip": Vector2(292, 62), "reach": 62.0, "motion": "still"},
	],
	"rodving": [
		{"chain": "wing", "joint": Vector2(225, 240), "tip": Vector2(40, 170), "reach": 75.0, "motion": "swing", "angle": 2.5, "period": 4.19},
		{"chain": "wing", "joint": Vector2(225, 240), "tip": Vector2(100, 330), "reach": 55.0, "motion": "still"},
		# The raised forearms paw the air, against each other.
		{"joint": Vector2(265, 330), "tip": Vector2(340, 380), "reach": 28.0, "motion": "swing", "angle": 4.0, "period": 8.38},
		{"joint": Vector2(285, 360), "tip": Vector2(305, 410), "reach": 22.0, "motion": "swing", "angle": 4.0, "period": 8.38, "phase": 0.5},
		# The burning tip of the tail, swaying its flame.
		{"chain": "tail", "joint": Vector2(300, 500), "tip": Vector2(360, 468), "reach": 22.0, "motion": "swing", "angle": 3.0, "period": 7.0},
		{"chain": "tail", "joint": Vector2(345, 475), "tip": Vector2(385, 365), "reach": 38.0, "motion": "still"},
		{"chain": "head", "joint": Vector2(262, 175), "tip": Vector2(350, 165), "reach": 40.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(262, 175), "tip": Vector2(268, 55), "reach": 48.0, "motion": "still"},
	],
	"vuurhast": [
		{"joint": Vector2(255, 300), "tip": Vector2(255, 150), "reach": 45.0, "motion": "swing", "angle": 1.5, "period": 8.38},
		# The head, its horns and its breath, riding on the neck.
		{"chain": "head", "joint": Vector2(255, 150), "tip": Vector2(335, 122), "reach": 40.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(255, 150), "tip": Vector2(205, 62), "reach": 32.0, "motion": "still"},
		{"chain": "head", "joint": Vector2(292, 165), "tip": Vector2(390, 178), "reach": 62.0, "motion": "still"},
		# The tail whips from the hip up its curl, the lightning at its tip with it.
		{"chain": "tail", "joint": Vector2(175, 430), "tip": Vector2(95, 395), "reach": 40.0, "motion": "swing", "angle": 2.5, "period": 7.0},
		{"chain": "tail", "joint": Vector2(95, 395), "tip": Vector2(95, 300), "reach": 32.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.07},
		{"chain": "tail", "joint": Vector2(95, 300), "tip": Vector2(112, 225), "reach": 28.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.14},
		{"chain": "tail", "joint": Vector2(112, 225), "tip": Vector2(95, 150), "reach": 100.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.21},
	],
	# The full-body pictures the ending screen draws, whole and uncut: the same
	# motions, measured again, and the tails that the card cuts off.
	"grimroch-full": [
		{"joint": Vector2(215, 268), "tip": Vector2(298, 412), "reach": 24.0, "motion": "swing", "angle": 2.5, "period": 8.38},
		{"joint": Vector2(380, 225), "tip": Vector2(420, 410), "reach": 32.0, "motion": "swing", "angle": 4.0, "period": 8.38, "phase": 0.5},
		{"chain": "head", "joint": Vector2(372, 150), "tip": Vector2(482, 170), "reach": 50.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(380, 150), "tip": Vector2(400, 70), "reach": 36.0, "motion": "still"},
		# A short, heavy tail, lashing from the hip round to its curled tip.
		{"chain": "tail", "joint": Vector2(185, 445), "tip": Vector2(95, 460), "reach": 40.0, "motion": "swing", "angle": 2.5, "period": 7.0},
		{"chain": "tail", "joint": Vector2(95, 460), "tip": Vector2(40, 400), "reach": 38.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.08},
		{"chain": "tail", "joint": Vector2(40, 400), "tip": Vector2(80, 330), "reach": 30.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.16},
		{"chain": "tail", "joint": Vector2(80, 330), "tip": Vector2(55, 290), "reach": 30.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.24},
	],
	"helsang-full": [
		{"chain": "wing", "joint": Vector2(265, 255), "tip": Vector2(60, 215), "reach": 80.0, "motion": "swing", "angle": 2.5, "period": 4.19},
		{"chain": "wing", "joint": Vector2(265, 255), "tip": Vector2(290, 120), "reach": 45.0, "motion": "still"},
		{"joint": Vector2(345, 330), "tip": Vector2(375, 440), "reach": 24.0, "motion": "swing", "angle": 4.0, "period": 8.38},
		{"chain": "tail", "joint": Vector2(225, 330), "tip": Vector2(150, 395), "reach": 34.0, "motion": "swing", "angle": 2.5, "period": 7.0},
		{"chain": "tail", "joint": Vector2(150, 395), "tip": Vector2(80, 425), "reach": 32.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.07},
		{"chain": "tail", "joint": Vector2(80, 425), "tip": Vector2(85, 335), "reach": 55.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.14},
		{"chain": "head", "joint": Vector2(365, 195), "tip": Vector2(450, 200), "reach": 40.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(365, 195), "tip": Vector2(360, 60), "reach": 62.0, "motion": "still"},
	],
	"rodving-full": [
		{"chain": "wing", "joint": Vector2(280, 240), "tip": Vector2(20, 190), "reach": 75.0, "motion": "swing", "angle": 2.5, "period": 4.19},
		{"chain": "wing", "joint": Vector2(280, 240), "tip": Vector2(190, 315), "reach": 55.0, "motion": "still"},
		{"chain": "wing", "joint": Vector2(280, 240), "tip": Vector2(295, 115), "reach": 40.0, "motion": "still"},
		{"joint": Vector2(340, 300), "tip": Vector2(415, 345), "reach": 28.0, "motion": "swing", "angle": 4.0, "period": 8.38},
		{"chain": "tail", "joint": Vector2(380, 470), "tip": Vector2(440, 450), "reach": 22.0, "motion": "swing", "angle": 3.0, "period": 7.0},
		{"chain": "tail", "joint": Vector2(425, 450), "tip": Vector2(470, 330), "reach": 40.0, "motion": "still"},
		{"chain": "head", "joint": Vector2(340, 150), "tip": Vector2(432, 128), "reach": 40.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(340, 150), "tip": Vector2(350, 30), "reach": 48.0, "motion": "still"},
	],
	"vuurhast-full": [
		{"joint": Vector2(292, 300), "tip": Vector2(292, 140), "reach": 48.0, "motion": "swing", "angle": 1.5, "period": 8.38},
		{"chain": "head", "joint": Vector2(292, 140), "tip": Vector2(385, 118), "reach": 42.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(292, 140), "tip": Vector2(240, 45), "reach": 34.0, "motion": "still"},
		{"chain": "head", "joint": Vector2(335, 155), "tip": Vector2(450, 160), "reach": 62.0, "motion": "still"},
		{"chain": "tail", "joint": Vector2(215, 440), "tip": Vector2(125, 410), "reach": 42.0, "motion": "swing", "angle": 2.5, "period": 7.0},
		{"chain": "tail", "joint": Vector2(125, 410), "tip": Vector2(125, 330), "reach": 34.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.07},
		{"chain": "tail", "joint": Vector2(125, 330), "tip": Vector2(155, 250), "reach": 30.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.14},
		{"chain": "tail", "joint": Vector2(155, 250), "tip": Vector2(140, 170), "reach": 110.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.21},
	],
	# The enemies move as the dragons do: the head lifts with the breath, carrying
	# its horns, hat or flames; a free arm drifts at half the breath; a tail lashes
	# from the hip. A held weapon turns whole about the hand, a bone each way along
	# it; a staff resting on the ground holds still. Region 1.
	"panda-fighter": [
		{"chain": "head", "joint": Vector2(285, 235), "tip": Vector2(355, 205), "reach": 40.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(285, 235), "tip": Vector2(292, 160), "reach": 30.0, "motion": "still"},
		{"joint": Vector2(350, 270), "tip": Vector2(402, 248), "reach": 26.0, "motion": "swing", "angle": 3.0, "period": 8.38},
		{"chain": "tail", "joint": Vector2(225, 340), "tip": Vector2(150, 315), "reach": 36.0, "motion": "swing", "angle": 2.5, "period": 7.0},
		{"chain": "tail", "joint": Vector2(150, 315), "tip": Vector2(60, 265), "reach": 42.0, "motion": "swing", "angle": 2.5, "period": 7.0, "phase": -0.07},
	],
	"monkey-brawler": [
		{"chain": "head", "joint": Vector2(310, 205), "tip": Vector2(405, 212), "reach": 48.0, "motion": "rise", "angle": -2.5, "period": 4.19, "phase": -0.1},
		# The breath curling from the jaw.
		{"chain": "head", "joint": Vector2(392, 250), "tip": Vector2(428, 318), "reach": 22.0, "motion": "still"},
	],
	"crane-monk": [
		{"chain": "head", "joint": Vector2(220, 195), "tip": Vector2(292, 170), "reach": 30.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(220, 195), "tip": Vector2(175, 170), "reach": 22.0, "motion": "still"},
		# The sword, with the water running off it, both ways from the grip.
		{"joint": Vector2(200, 308), "tip": Vector2(415, 310), "reach": 58.0, "motion": "swing", "angle": 1.5, "period": 8.38},
		{"joint": Vector2(200, 308), "tip": Vector2(150, 308), "reach": 12.0, "motion": "swing", "angle": 1.5, "period": 8.38},
	],
	"lion-archer": [
		{"chain": "head", "joint": Vector2(240, 222), "tip": Vector2(282, 205), "reach": 34.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "tail", "joint": Vector2(155, 415), "tip": Vector2(120, 400), "reach": 18.0, "motion": "swing", "angle": 3.0, "period": 7.0},
		{"chain": "tail", "joint": Vector2(120, 400), "tip": Vector2(122, 355), "reach": 18.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.07},
		{"chain": "tail", "joint": Vector2(122, 355), "tip": Vector2(75, 335), "reach": 28.0, "motion": "swing", "angle": 3.0, "period": 7.0, "phase": -0.14},
	],
	# Region 2.
	"axe-gnome": [
		{"chain": "head", "joint": Vector2(215, 340), "tip": Vector2(285, 290), "reach": 40.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(215, 300), "tip": Vector2(135, 185), "reach": 30.0, "motion": "still"},
		{"joint": Vector2(140, 300), "tip": Vector2(78, 315), "reach": 24.0, "motion": "swing", "angle": 4.0, "period": 8.38, "phase": 0.5},
		{"joint": Vector2(297, 373), "tip": Vector2(385, 320), "reach": 52.0, "motion": "swing", "angle": 2.0, "period": 8.38},
		{"joint": Vector2(297, 373), "tip": Vector2(255, 395), "reach": 12.0, "motion": "swing", "angle": 2.0, "period": 8.38},
	],
	"club-ogre": [
		{"chain": "head", "joint": Vector2(230, 165), "tip": Vector2(282, 140), "reach": 36.0, "motion": "rise", "angle": -2.5, "period": 4.19, "phase": -0.1},
		{"joint": Vector2(95, 185), "tip": Vector2(72, 360), "reach": 46.0, "motion": "swing", "angle": 2.5, "period": 8.38, "phase": 0.5},
		{"joint": Vector2(307, 353), "tip": Vector2(425, 395), "reach": 62.0, "motion": "swing", "angle": 1.5, "period": 8.38},
		{"joint": Vector2(307, 353), "tip": Vector2(275, 325), "reach": 10.0, "motion": "swing", "angle": 1.5, "period": 8.38},
	],
	"horned-goblin": [
		{"chain": "head", "joint": Vector2(265, 315), "tip": Vector2(322, 305), "reach": 36.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(265, 300), "tip": Vector2(232, 200), "reach": 26.0, "motion": "still"},
		{"chain": "head", "joint": Vector2(265, 300), "tip": Vector2(262, 212), "reach": 20.0, "motion": "still"},
		{"joint": Vector2(303, 383), "tip": Vector2(395, 293), "reach": 24.0, "motion": "swing", "angle": 2.0, "period": 8.38},
		{"joint": Vector2(303, 383), "tip": Vector2(272, 408), "reach": 10.0, "motion": "swing", "angle": 2.0, "period": 8.38},
	],
	"marsh-treant": [
		{"chain": "head", "joint": Vector2(318, 155), "tip": Vector2(398, 150), "reach": 45.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(318, 155), "tip": Vector2(285, 35), "reach": 55.0, "motion": "still"},
		{"chain": "head", "joint": Vector2(318, 155), "tip": Vector2(390, 60), "reach": 40.0, "motion": "still"},
		# The reaching arm, with the breath at its hand, against the trailing one.
		{"joint": Vector2(320, 225), "tip": Vector2(455, 300), "reach": 38.0, "motion": "swing", "angle": 3.0, "period": 8.38},
		{"joint": Vector2(175, 180), "tip": Vector2(125, 345), "reach": 58.0, "motion": "swing", "angle": 2.0, "period": 8.38, "phase": 0.5},
	],
	# Region 3.
	"naga": [
		{"chain": "head", "joint": Vector2(313, 113), "tip": Vector2(405, 105), "reach": 38.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(380, 125), "tip": Vector2(415, 225), "reach": 24.0, "motion": "still"},
		# The tail coils out from under the robe and up to the flame at its tip.
		{"chain": "tail", "joint": Vector2(205, 462), "tip": Vector2(115, 465), "reach": 28.0, "motion": "swing", "angle": 2.0, "period": 7.0},
		{"chain": "tail", "joint": Vector2(115, 465), "tip": Vector2(150, 385), "reach": 30.0, "motion": "swing", "angle": 2.0, "period": 7.0, "phase": -0.07},
		{"chain": "tail", "joint": Vector2(150, 385), "tip": Vector2(85, 315), "reach": 45.0, "motion": "swing", "angle": 2.0, "period": 7.0, "phase": -0.14},
	],
	# Two heads, lifting out of step.
	"twin-ogre": [
		{"chain": "left", "joint": Vector2(272, 122), "tip": Vector2(322, 100), "reach": 34.0, "motion": "rise", "angle": -2.5, "period": 4.19, "phase": -0.1},
		{"chain": "right", "joint": Vector2(340, 135), "tip": Vector2(390, 108), "reach": 32.0, "motion": "rise", "angle": -2.5, "period": 4.19, "phase": 0.35},
		{"joint": Vector2(132, 155), "tip": Vector2(92, 335), "reach": 48.0, "motion": "swing", "angle": 2.0, "period": 8.38, "phase": 0.5},
	],
	"twin-ghoul": [
		{"chain": "left", "joint": Vector2(232, 222), "tip": Vector2(275, 222), "reach": 34.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "left", "joint": Vector2(232, 205), "tip": Vector2(262, 45), "reach": 26.0, "motion": "still"},
		{"chain": "right", "joint": Vector2(295, 212), "tip": Vector2(338, 255), "reach": 30.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": 0.35},
		{"chain": "right", "joint": Vector2(295, 195), "tip": Vector2(322, 58), "reach": 24.0, "motion": "still"},
	],
	"boar-shaman": [
		{"chain": "head", "joint": Vector2(272, 295), "tip": Vector2(375, 285), "reach": 40.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(272, 280), "tip": Vector2(280, 218), "reach": 22.0, "motion": "still"},
		# The spear, raised, both ways from the fist.
		{"joint": Vector2(170, 165), "tip": Vector2(420, 202), "reach": 30.0, "motion": "swing", "angle": 1.0, "period": 8.38},
		{"joint": Vector2(170, 165), "tip": Vector2(85, 152), "reach": 10.0, "motion": "swing", "angle": 1.0, "period": 8.38},
		{"chain": "tail", "joint": Vector2(160, 410), "tip": Vector2(125, 435), "reach": 14.0, "motion": "swing", "angle": 4.0, "period": 7.0},
		{"chain": "tail", "joint": Vector2(125, 435), "tip": Vector2(105, 462), "reach": 20.0, "motion": "swing", "angle": 4.0, "period": 7.0, "phase": -0.07},
	],
	# Region 4.
	"hedge-wizard": [
		{"chain": "head", "joint": Vector2(280, 250), "tip": Vector2(335, 232), "reach": 36.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(280, 240), "tip": Vector2(235, 112), "reach": 40.0, "motion": "still"},
		{"chain": "head", "joint": Vector2(280, 225), "tip": Vector2(350, 178), "reach": 18.0, "motion": "still"},
	],
	"goblin-hexer": [
		{"chain": "head", "joint": Vector2(232, 258), "tip": Vector2(318, 255), "reach": 32.0, "motion": "rise", "angle": -3.0, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(232, 245), "tip": Vector2(225, 152), "reach": 40.0, "motion": "still"},
	],
	"antler-horror": [
		{"chain": "head", "joint": Vector2(325, 220), "tip": Vector2(412, 248), "reach": 42.0, "motion": "rise", "angle": -2.5, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(325, 205), "tip": Vector2(238, 50), "reach": 42.0, "motion": "still"},
		{"chain": "head", "joint": Vector2(325, 205), "tip": Vector2(310, 72), "reach": 46.0, "motion": "still"},
		{"chain": "head", "joint": Vector2(330, 205), "tip": Vector2(398, 155), "reach": 30.0, "motion": "still"},
		{"joint": Vector2(88, 292), "tip": Vector2(65, 338), "reach": 14.0, "motion": "swing", "angle": 4.0, "period": 7.0},
	],
	"gath-brute": [
		{"chain": "head", "joint": Vector2(325, 155), "tip": Vector2(402, 167), "reach": 36.0, "motion": "rise", "angle": -2.5, "period": 4.19, "phase": -0.1},
		{"chain": "head", "joint": Vector2(345, 120), "tip": Vector2(383, 85), "reach": 20.0, "motion": "still"},
		{"joint": Vector2(113, 155), "tip": Vector2(67, 320), "reach": 34.0, "motion": "swing", "angle": 3.0, "period": 8.38, "phase": 0.5},
		{"joint": Vector2(375, 222), "tip": Vector2(447, 307), "reach": 32.0, "motion": "swing", "angle": 3.0, "period": 8.38},
	],
}
## The ways a bone can move, as the shader numbers them.
const MOVES := {"still": 0, "swing": 1, "rise": 2}


## A dragon's full-body picture (<name>-full, the ending screen's) idles as the
## dragon does.
static func motion(name: String) -> String:
	return MOTION.get(name.trim_suffix("-full"), "still")


static func speed(name: String) -> float:
	return SPEED.get(name.trim_suffix("-full"), 1.0)


## The soft bones a picture bends by, or []: each as in BONES, and last, the index
## of the last bone it carries (itself, or the tip of its chain).
static func bones(name: String) -> Array:
	var list: Array = BONES.get(name, [])
	var out := []
	for i in list.size():
		var bone: Dictionary = list[i].duplicate()
		bone.last = i
		var chain: String = bone.get("chain", "")
		while chain != "" and bone.last + 1 < list.size() and list[bone.last + 1].get("chain", "") == chain:
			bone.last += 1
		out.append(bone)
	return out


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
