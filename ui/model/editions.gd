extends RefCounted
## Classic or House rules: one game, two editions, chosen in the menu's Rules setting.
## Classic is the rulebook as printed; House rules adds this edition's own alternate
## rules beside the rulebook's. The engine knows nothing of editions: each house rule
## is a game option with its own check there (Game.keeps_xp()), so Classic is simply
## every house rule off. This gate decides only what is offered and described.

const Settings = preload("res://ui/model/settings.gd")

## The game options that are house rules, not the rulebook's.
const HOUSE_RULES := ["persistent_xp"]
## Starts a rulebook or glossary string that only House rules shows.
const HOUSE_MARK := "{house}"


static func house() -> bool:
	return Settings.house_rules


## Whether the setup screens offer the option `key`.
static func offers(key: String) -> bool:
	return house() or not HOUSE_RULES.has(key)


## `options` as a game may start with them: under Classic, every house rule off, so a
## remembered choice never carries one into a Classic game.
static func apply(options: Dictionary) -> Dictionary:
	var out := options.duplicate()
	if not house():
		for key in HOUSE_RULES:
			if out.has(key):
				out[key] = false
	return out


## `text` for the edition in play: a string marked HOUSE_MARK comes back unmarked
## under House rules and as "" under Classic; any other string as it is.
static func text(s: String) -> String:
	if not s.begins_with(HOUSE_MARK):
		return s
	return s.substr(HOUSE_MARK.length()) if house() else ""
