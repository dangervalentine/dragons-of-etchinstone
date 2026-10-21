extends RefCounted
## What the board does when something happens: the zones answer each action with a
## flat change of their edge colour, not only the card involved. Each answer has a
## moving form and a still one for reduced motion. Pure: a table and a lookup.

## event -> {target, colour, motion: {kind, duration}, still: {...}}.
## target: a zone: "hand", "encounter", "header" or "slot" (a role slot).
## colour: "ether" (the card's or the Encounter's), "focus", "gold", "bad" or "neutral".
const TABLE := {
	"place": {"target": "slot", "colour": "ether", "motion": {"kind": "flare", "duration": 0.25},
		"still": {"tint": "ether", "hold": 0.25}},
	"take_back": {"target": "slot", "colour": "neutral", "motion": {"kind": "dim", "duration": 0.15},
		"still": {"clear": true}},
	"fuse": {"target": "hand", "colour": "ether", "motion": {"kind": "flare", "duration": 0.35},
		"still": {"tint": "ether", "hold": 0.25}},
	"divert": {"target": "header", "colour": "neutral", "motion": {"kind": "sweep", "duration": 0.35},
		"still": {"tint": "neutral", "hold": 0.25}},
	"regroup": {"target": "header", "colour": "neutral", "motion": {"kind": "sweep", "duration": 0.35},
		"still": {"tint": "neutral", "hold": 0.25}},
	"play": {"target": "encounter", "colour": "ether", "motion": {"kind": "flare", "duration": 0.4},
		"still": {"tint": "ether", "hold": 0.25}},
	"hit_enemy": {"target": "encounter", "colour": "ether", "motion": {"kind": "shudder", "duration": 0.35},
		"still": {"tint": "ether", "hold": 0.25}},
	"take_damage": {"target": "hand", "colour": "bad", "motion": {"kind": "flare", "duration": 0.35},
		"still": {"tint": "bad", "hold": 0.25}},
	"soak": {"target": "hand", "colour": "bad", "motion": {"kind": "flare", "duration": 0.25},
		"still": {"tint": "bad", "hold": 0.25}},
	"upgrade": {"target": "hand", "colour": "gold", "motion": {"kind": "flare", "duration": 0.4},
		"still": {"tint": "gold", "hold": 0.25}},
	"encounter_won": {"target": "encounter", "colour": "gold", "motion": {"kind": "flare", "duration": 0.4},
		"still": {"tint": "gold", "hold": 0.25}},
	"encounter_lost": {"target": "encounter", "colour": "bad", "motion": {"kind": "dim", "duration": 0.4},
		"still": {"tint": "bad", "hold": 0.25}},
}

## Sequence steps the board leaves to the cards, the counters and the banner.
const QUIET_STEPS := ["tally", "gain_xp", "pay_time", "poison_pending", "downgrade", "trash",
	"discard", "gather_shuffle", "shuffle", "stage_banner", "draw", "ending"]


## The event a sequence step stands for, or "" when the board stays quiet.
## encounter_kind: "enemy", "journey", "final_journey" or "final_enemy".
static func for_step(kind: String, values: Dictionary, encounter_kind: String) -> String:
	match kind:
		"play_cards":
			return "hit_enemy" if encounter_kind == "enemy" or encounter_kind == "final_enemy" else "play"
		"verdict":
			return "encounter_lost" if values.get("outcome", "") == "loss" else "encounter_won"
		"damage":
			return "take_damage" if int(values.get("amount", 0)) > 0 else ""
		"knock_out":
			return "take_damage"
		"upgrade":
			return "upgrade"
	return ""
