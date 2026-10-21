extends RefCounted
## The six lessons of Learn to Play (specs/017, contracts/lessons.md): each a staged
## table set out by Game.stage() and the steps that walk the player through it. The
## tables were found by search and checked against the engine (research R1);
## tests/test_lessons.gd proves every lesson still gives its outcome.
##
## A step is {"text", "target", "wait", "expect"?, "hint"?, "concepts"?}:
##   text      Rulebook marks ([[id]], [[id|words]], {icon:id}, {n:NAME}); the terms
##             become links that open the Glossary (see text())
##   target    what the coach mark lights (contracts/coach-mark.md); "screen" is nothing
##   wait      "next" for a message read, or the move that moves it on: dragon, setup,
##             arrange, play, soak, upgrade, fuse_begin, fuse_element, or sequence: the
##             animation that a move set off, played with no mark shown (its text
##             says what it shows; what to say after it is the next step's)
##   expect    the guided move (data-model.md "Step"); hint is shown when it differs
##   concepts  the FR-012 ideas the step explains (CONCEPTS)

const Rulebook = preload("res://ui/model/rulebook.gd")

## Every idea the lessons must explain, each named by at least one step (SC-004).
const CONCEPTS := ["deck", "key_card", "hardship", "ether", "enhanced", "roles", "reserve",
	"enemy_figures", "initiative", "outcomes", "journey", "time_penalty", "deck_clock",
	"region_end", "soak", "armor", "downgrade", "trash", "upgrade", "unspent_xp", "cleanup",
	"fuse", "divert"]

## What a step may light: an exact name, or a prefix followed by an id.
const TARGETS := ["screen", "deck", "key", "encounter", "hand", "aim", "primary", "picker", "soak", "xp"]
const TARGET_PREFIXES := ["chip:", "card:", "ether:", "place:", "action:", "dragon:"]

const WAITS := ["next", "dragon", "setup", "arrange", "play", "soak", "upgrade", "fuse_begin",
	"fuse_element", "sequence"]

const DESTRUCTION := "DOE-A03"

const LESSONS := [
	{
		"id": "setting_out", "title": "Setting Out", "outcome": "setup",
		"table": {"phase": "setup", "region": 1, "hand": [], "discard": [], "trash": [],
			"deck": ["DOE-A03", "DOE-A06", "DOE-A12", "DOE-A15", "DOE-A16"], "deck_rest": true,
			"setup_offer": ["DOE-A03", "DOE-A06", "DOE-A12", "DOE-A15", "DOE-A16"],
			"setup_picks": 1, "setup_level": 3},
		"steps": [
			{"target": "screen", "wait": "next",
				"text": "Welcome to Vale. You are a mage of the Tower, sent across four Regions to hunt a dragon. Each lesson teaches one part of the hunt."},
			{"target": "dragon:rodving", "wait": "dragon", "expect": {"dragon": "rodving"},
				"hint": "Every lesson is played against Rodving.",
				"text": "Start by selecting which dragon you wish to hunt. Reports spoting Rodving nearby have been received. Press Continue."},
			{"target": "hand", "wait": "next", "concepts": ["deck"],
				"text": "Next, we will prepare for the journey ahead. Some difficulties let you raise a few cards before you set out. These five cards come from your [[deck|Deck]]. Here you raise one, to Level 3."},
			{"target": "card:DOE-A03", "wait": "setup", "expect": {"picks": ["DOE-A03"]}, "concepts": ["upgrade"],
				"hint": "Choose Destruction: it is the one that fights.",
				"text": "Choose Destruction, in order to upgrade it before setting out. At Level 3 Desctruction's fire {icon:attack} Attack rises to 10, making it a potent spell in the quest ahead."},
			{"target": "screen", "wait": "sequence", "text": "Your first Hand is dealt."},
		],
	},
	{
		"id": "victory", "title": "A Victory", "outcome": "complete",
		"table": {"phase": "challenge", "region": 1, "levels": {"DOE-A03": 3},
			"deck": ["DOE-A05"], "deck_rest": true, "hand": ["DOE-A10", "DOE-A14", "DOE-A06", "DOE-A03"],
			"discard": [], "trash": []},
		"steps": [
			{"target": "deck", "wait": "next", "concepts": ["deck"],
				"text": "This is your [[deck|Deck]]: every card you have. Each Encounter, your Hand is drawn from it."},
			{"target": "key", "wait": "next", "concepts": ["key_card", "hardship"],
				"text": "The card on top is the [[key_card|Key Card]]. Its strip names the Encounter you face, and can bring a Hardship that makes it harder. There is none here."},
			{"target": "encounter", "wait": "next", "concepts": ["enemy_figures"],
				"text": "An [[enemy]]. It has {icon:hp} HP to beat, {icon:initiative} Initiative, {icon:attack} Attack and {icon:armor} Armor, and is worth the {icon:xp} XP shown."},
			{"target": "ether:DOE-A03", "wait": "next", "concepts": ["ether", "enhanced"],
				"text": "Every card belongs to an Ether, shown by its colour and mark. When your Element's Ether matches the Spell's [[enhanced|enhanced action]], you get the enhanced value."},
			{"target": "card:DOE-A06+DOE-A03", "wait": "arrange", "concepts": ["roles"],
				"expect": {"places": {"0/spell": "DOE-A03", "0/boost": "DOE-A06"}},
				"text": "Three cards make your Action Set. The [[spell|Spell]] is what you do, the [[element_role|Element]] lends its Ether and Initiative, the [[boost_role|Boost]] adds to it. Tap Destruction, then Fleet Footed, to swap Destruction into the Spell's place."},
			{"target": "place:reserve", "wait": "next", "concepts": ["reserve"],
				"text": "The card left out is your [[reserve|Reserve]]. It stays in your Hand for the next Encounter."},
			{"target": "chip:initiative", "wait": "next", "concepts": ["initiative"],
				"text": "Frostfire Wall's Initiative of 5 beats the enemy's 4, so it cannot strike before you."},
			{"target": "aim", "wait": "next",
				"text": "Against an enemy you choose where the Boost goes. Put it on Attack."},
			{"target": "primary", "wait": "play", "concepts": ["outcomes"],
				"expect": {"spell": "DOE-A03", "element": "DOE-A14", "boost": "DOE-A06", "boost_to": "attack"},
				"hint": "Spell: Destruction. Element: Frostfire Wall. Boost: Fleet Footed, on Attack.",
				"text": "Destruction's fire Attack is 10, plus 2 from the Boost, less 1 for the enemy's fire Armor: 11, its HP exactly. HP or more is a [[victory|Victory]]. Play it."},
			{"target": "screen", "wait": "sequence", "text": "The enemy falls."},
			{"target": "card:DOE-A10", "wait": "next", "concepts": ["upgrade", "unspent_xp"],
				"text": "Victory earns its {icon:xp} XP, spent now to [[upgrade|Upgrade]] cards in your Hand. Rain of Blood is your Reserve and stays with you, so raise it. XP left unspent is lost."},
			{"target": "card:DOE-A10", "wait": "upgrade", "expect": {"picks": ["DOE-A10"]}, "concepts": ["cleanup"],
				"hint": "Upgrade Rain of Blood, once, then confirm.",
				"text": "Tap Rain of Blood once and confirm. Then Cleanup: your Action Set is discarded and you draw back up to {n:HAND_SIZE}."},
			{"target": "screen", "wait": "sequence", "text": "Your Hand is drawn back up."},
			{"target": "deck", "wait": "next",
				"text": "Your Reserve stayed in your Hand, and the Deck is smaller by the cards you drew."},
		],
	},
	{
		"id": "narrow", "title": "A Narrow Victory", "outcome": "narrow",
		"table": {"phase": "challenge", "region": 1, "deck": ["DOE-A08"], "deck_rest": true,
			"hand": ["DOE-A05", "DOE-A01", "DOE-A09", "DOE-A13"], "discard": [], "trash": []},
		"steps": [
			{"target": "encounter", "wait": "next", "concepts": ["journey"],
				"text": "A [[journey|Journey]]. You cross it with {icon:move} Move against its {icon:mp} MP. There is no Initiative and no Early Damage, and falling short costs time, not cards."},
			{"target": "chip:time", "wait": "next", "concepts": ["time_penalty"],
				"text": "Its [[time|Time Penalty]] is 2."},
			{"target": "place:0/spell", "wait": "next", "concepts": ["enhanced"],
				"text": "This Hand is dealt in place. River Swiftness moves 6 with water, and Brute Force brings water."},
			{"target": "primary", "wait": "play", "concepts": ["outcomes"],
				"expect": {"spell": "DOE-A09", "element": "DOE-A01", "boost": "DOE-A13", "boost_to": "attack"},
				"hint": "Spell: River Swiftness. Element: Brute Force. Boost: Adapt.",
				"text": "6 and 3 make 9 against 12. Half the MP or more is a [[narrow_victory|Narrow Victory]]: you earn the XP but pay the time. Play it."},
			{"target": "screen", "wait": "sequence", "text": "Across, narrowly."},
			{"target": "deck", "wait": "next", "concepts": ["deck_clock"],
				"text": "Two cards leave the top of your Deck. The Deck is also your clock: every card lost brings the end of the Region closer."},
			{"target": "xp", "wait": "upgrade", "expect": {}, "concepts": ["cleanup"],
				"text": "Spend the XP on any card if you like, then confirm."},
		],
	},
	{
		"id": "loss", "title": "A Loss", "outcome": "loss",
		"table": {"phase": "challenge", "region": 1, "deck": ["DOE-A07"], "deck_rest": true,
			"hand": ["DOE-A09", "DOE-A06", "DOE-A13", "DOE-A01"], "discard": [], "trash": []},
		"steps": [
			{"target": "encounter", "wait": "next", "concepts": ["outcomes", "divert"],
				"text": "This enemy has 13 HP, and nothing in your Hand reaches half of it. When an Encounter cannot be won you may [[divert|Divert]] it, at a cost. Here, take the [[loss|Loss]]."},
			{"target": "primary", "wait": "play",
				"expect": {"spell": "DOE-A13", "element": "DOE-A06", "boost": "DOE-A01", "boost_to": "attack"},
				"hint": "Spell: Adapt. Element: Fleet Footed. Boost: Brute Force.",
				"text": "Fleet Footed is faster than the enemy, so at least it does not strike first. Play it."},
			{"target": "screen", "wait": "sequence", "text": "The enemy strikes back."},
			{"target": "soak", "wait": "next", "concepts": ["soak"],
				"text": "3 shadow damage. You [[soak|Soak]] it by Downgrading cards in your Hand."},
			{"target": "hand", "wait": "next", "concepts": ["armor"],
				"text": "Each card Soaks its {icon:armor} Armor: River Swiftness 2, Fleet Footed 3, Adapt 2, Brute Force 2. Armor of the damage's own Ether counts double; none of these is shadow."},
			{"target": "card:DOE-A06", "wait": "soak", "expect": {"picks": ["DOE-A06"]}, "concepts": ["downgrade"],
				"hint": "Soak with Fleet Footed.",
				"text": "Fleet Footed's Armor 3 covers it alone. Choose it and confirm: it goes down a Level, a [[downgrade|Downgrade]]."},
			{"target": "screen", "wait": "next", "concepts": ["trash"],
				"text": "A Level 1 card that is Downgraded is [[trash|Trashed]], gone for good. Fleet Footed is at Level 1 now: guard it."},
			{"target": "primary", "wait": "upgrade", "expect": {},
				"text": "There is no XP to spend. Confirm to end the Encounter."},
		],
	},
	{
		"id": "fuse", "title": "Fusing", "outcome": "fuse_complete",
		"table": {"phase": "challenge", "region": 1, "deck": ["DOE-A01"], "deck_rest": true,
			"hand": ["DOE-A03", "DOE-A02", "DOE-A05", "DOE-A09"], "discard": [], "trash": []},
		"steps": [
			{"target": "encounter", "wait": "next",
				"text": "9 HP, with Armor against water. The best Action Set in your Hand falls short."},
			{"target": "card:DOE-A02+DOE-A03", "wait": "next", "concepts": ["fuse"],
				"text": "Sword of Light and Destruction are both water. Two cards of one Ether can [[fuse|Fuse]]: the top card fills a Role and counts as any Ether you choose, the bottom fills none. It needs a full Hand, and both are discarded at Cleanup."},
			{"target": "action:fuse", "wait": "fuse_begin",
				"hint": "Press Fuse.",
				"text": "Press Fuse."},
			{"target": "picker", "wait": "fuse_element",
				"expect": {"top": "DOE-A02", "bottom": "DOE-A03", "element": "fire"},
				"hint": "Fuse Sword of Light over Destruction, as fire.",
				"text": "Choose Sword of Light, then Destruction beneath it, and make the pair fire."},
			{"target": "primary", "wait": "play",
				"expect": {"spell": "DOE-A05", "element": "DOE-A02", "boost": "DOE-A09", "boost_to": "attack",
					"fuse": {"top": "DOE-A02", "bottom": "DOE-A03", "element": "fire"}},
				"hint": "Spell: Rain of Blood. Element: the fused Sword of Light. Boost: River Swiftness.",
				"text": "Sword of Light now brings fire, so Rain of Blood's Attack is enhanced: 8 and 2 make 10 against 9. Play it."},
			{"target": "screen", "wait": "sequence", "text": "A Victory no plain Action Set could reach."},
			{"target": "primary", "wait": "upgrade", "expect": {}, "concepts": ["cleanup"],
				"text": "Spend the XP if you like, then confirm. Both Fused cards are discarded at Cleanup: Fusing cost you a card you could have kept."},
		],
	},
	{
		"id": "region_end", "title": "The End of a Region", "outcome": "region_end",
		"table": {"phase": "challenge", "region": 1, "deck": ["DOE-A09", "DOE-A16"],
			"hand": ["DOE-A05", "DOE-A10", "DOE-A13", "DOE-A01"], "discard": "rest", "trash": []},
		"steps": [
			{"target": "deck", "wait": "next", "concepts": ["region_end"],
				"text": "Two cards are left in your Deck. A Region lasts while your Hand and Deck together can give a fresh Hand and a Key Card: five cards."},
			{"target": "primary", "wait": "play",
				"expect": {"spell": "DOE-A13", "element": "DOE-A10", "boost": "DOE-A01", "boost_to": "attack"},
				"hint": "Spell: Adapt. Element: Rain of Blood. Boost: Brute Force.",
				"text": "Adapt's Move is enhanced by shadow: 5 and 3 make 8, the MP exactly. Play it."},
			{"target": "screen", "wait": "sequence", "text": "Across."},
			{"target": "primary", "wait": "upgrade", "expect": {},
				"text": "Confirm. After Cleanup only three cards are left: the Region is over."},
			{"target": "screen", "wait": "sequence", "text": "The Region ends."},
			{"target": "deck", "wait": "next",
				"text": "Every card that is not Trashed is gathered and shuffled into a new Deck."},
			{"target": "screen", "wait": "next",
				"text": "Region 2 is dealt, and your cards keep their Levels. After Region 4 comes the Final Battle against the dragon."},
		],
	},
]

## Shown after the last lesson (contracts/tutorial-flow.md).
const SUMMARY := "You have read the [[key_card|Key Card]], matched Ether for an [[enhanced|enhanced action]], won, scraped through and lost, [[soak|Soaked]] damage, [[fuse|Fused]] two cards and seen a Region end. A full game crosses four Regions, then the Final Journey to the dragon and the Final Enemy, the dragon itself."

static var _term_re: RegEx


static func count() -> int:
	return LESSONS.size()


static func lesson(i: int) -> Dictionary:
	return LESSONS[i]


static func index_of(id: String) -> int:
	for i in LESSONS.size():
		if LESSONS[i].id == id:
			return i
	return -1


static func ids() -> Array:
	return LESSONS.map(func(l): return l.id)


## The lesson's table as Game.stage() takes it: "deck_rest" appends every card not
## otherwise placed to the Deck, in id order, after the cards listed.
static func table(i: int, card_ids: Array) -> Dictionary:
	var t: Dictionary = LESSONS[i].table.duplicate(true)
	if t.get("deck_rest", false):
		var placed: Array = t.deck + t.hand + (t.discard if t.discard is Array else []) + t.trash
		var rest := card_ids.filter(func(id): return not placed.has(id))
		rest.sort()
		t.deck = t.deck + rest
	t.erase("deck_rest")
	return t


## A step's text as BBCode: every [[term]] a link to its Glossary entry, then the
## Rulebook's icons and numbers.
static func text(s: String) -> String:
	if _term_re == null:
		_term_re = RegEx.create_from_string("\\[\\[([a-z_]+)(?:\\|([^\\]]+))?\\]\\]")
	var out := s
	for m in _term_re.search_all(s):
		var id := m.get_string(1)
		var words: String = m.get_string(2) if m.get_string(2) != "" else Rulebook.Glossary.entry(id).name
		out = out.replace(m.get_string(0), "[url=%s][b]%s[/b][/url]" % [id, words])
	return Rulebook.expand(out)


## Every [[term]] id in a text.
static func terms(s: String) -> Array:
	return Rulebook.terms_in([s])
