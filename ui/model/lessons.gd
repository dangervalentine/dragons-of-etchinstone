extends RefCounted
## The six lessons of Learn to Play (specs/017, contracts/lessons.md): each a staged
## table set out by Game.stage() and the steps that walk the player through it. The
## tables were found by search and checked against the engine (research R1);
## tests/test_lessons.gd proves every lesson still gives its outcome.
##
## A step is {"text", "target", "wait", "expect"?, "hint"?, "concepts"?}:
##   text      Rulebook marks ([[id]], [[id|words]], {icon:id}, {n:NAME}); the terms
##             become links that open the Glossary (see text())
##   target    what the coach mark lights (contracts/coach-mark.md); "screen" is nothing;
##             "a|b" lights several, the message beside the first
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
				"text": "Dragons have crawled out of the rifts and into Vale. The Tower has chosen you, its newest mage, to cross four Regions and slay one. These lessons ready you for the road, one skill at a time."},
			{"target": "dragon:rodving", "wait": "dragon", "expect": {"dragon": "rodving"},
				"hint": "Rodving is your quarry on this hunt.",
				"text": "Scouts bring word: Rodving, the Last Breath, has been seen burning the Jade Mountains. It will be your quarry. Press Continue."},
			{"target": "hand", "wait": "next", "concepts": ["deck"],
				"text": "Before you set out, make ready. These five spells are drawn from your [[deck|Deck]], the spellbook you carry into every fight. On some difficulties you may sharpen a few before leaving; here you sharpen one, to Level 3."},
			{"target": "card:DOE-A03", "wait": "setup", "expect": {"picks": ["DOE-A03"]}, "concepts": ["upgrade"],
				"hint": "Destruction is your only war spell: choose it.",
				"text": "Choose Destruction and confirm. It is the only war spell among them; at Level 3 its fire {icon:attack} Attack rises to 10, enough to break the first foe on your road."},
			{"target": "screen", "wait": "sequence", "text": "The road begins: your first Hand is dealt."},
		],
	},
	{
		"id": "victory", "title": "A Victory", "outcome": "complete",
		"table": {"phase": "challenge", "region": 1, "levels": {"DOE-A03": 3},
			"deck": ["DOE-A05"], "deck_rest": true, "hand": ["DOE-A10", "DOE-A14", "DOE-A06", "DOE-A03"],
			"discard": [], "trash": []},
		"steps": [
			{"target": "deck", "wait": "next", "concepts": ["deck"],
				"text": "Your [[deck|Deck]] is your spellbook: every spell you carry on the hunt. Before each Encounter on the road, your Hand is drawn from it."},
			{"target": "key", "wait": "next", "concepts": ["key_card", "hardship"],
				"text": "The spell on top is the [[key_card|Key Card]]. It foretells what waits on the road ahead, named here, and can bring a Hardship that makes the meeting worse. The road is kind today: none."},
			{"target": "encounter", "wait": "next", "concepts": ["enemy_figures"],
				"text": "A Lionel Archer bars the way, an [[enemy]]. Beat its {icon:hp} HP to bring it down, and mind its {icon:initiative} Initiative, {icon:attack} Attack and {icon:armor} Armor. Felling it earns the {icon:xp} XP shown."},
			{"target": "ether:DOE-A03", "wait": "next", "concepts": ["ether", "enhanced"],
				"text": "Every spell draws on one of the four Ethers, shown by its colour and mark. When your Element's Ether matches the Spell's [[enhanced|enhanced action]], the spell burns at full strength."},
			{"target": "card:DOE-A06+DOE-A03", "wait": "arrange", "concepts": ["roles"],
				"expect": {"places": {"0/spell": "DOE-A03", "0/boost": "DOE-A06"}},
				"text": "Three spells make an Action Set. The [[spell|Spell]] is the blow you strike, the [[element_role|Element]] lends its Ether and Initiative, the [[boost_role|Boost]] lends its strength. Tap Destruction, then Fleet Footed, to swap Destruction into the Spell's place."},
			{"target": "place:reserve", "wait": "next", "concepts": ["reserve"],
				"text": "The spell left out is your [[reserve|Reserve]], kept back in your Hand for the next Encounter on the road."},
			{"target": "chip:initiative|card:DOE-A14", "wait": "next", "concepts": ["initiative"],
				"text": "Frostfire Wall's Initiative of 5 beats the archer's 4: your spell flies before its arrows do."},
			{"target": "aim", "wait": "next",
				"text": "Against a foe you choose where the Boost goes: a quicker hand or a harder blow. Put it on Attack."},
			{"target": "primary", "wait": "play", "concepts": ["outcomes"],
				"expect": {"spell": "DOE-A03", "element": "DOE-A14", "boost": "DOE-A06", "boost_to": "attack"},
				"hint": "Strike with Destruction, Frostfire Wall as Element and Fleet Footed's Boost on Attack.",
				"text": "Destruction's fire Attack is 10, plus 2 from the Boost (12), take away 1 because of the archer's fire Armor and you have 11. Reaching their HP or higher makes this encounter a [[victory|Victory]] for you. Strike."},
			{"target": "screen", "wait": "sequence", "text": "The archer falls."},
			{"target": "card:DOE-A10|card:DOE-A06", "wait": "next", "concepts": ["upgrade", "unspent_xp"],
				"text": "Victory earns 7 {icon:xp} XP, spent now to [[upgrade|Upgrade]] spells in your Hand, and XP left unspent is lost to the wind. Rain of Blood costs 3 and Fleet Footed 4: together, every point of it."},
			{"target": "card:DOE-A10|card:DOE-A06", "wait": "upgrade", "expect": {"picks": ["DOE-A10", "DOE-A06"]}, "concepts": ["cleanup"],
				"hint": "Raise Rain of Blood and Fleet Footed once each: all 7 XP.",
				"text": "Tap Rain of Blood and Fleet Footed once each, then confirm. Then you make camp, the Cleanup: the spells you cast are discarded, keeping their new Levels, and you draw back up to {n:HAND_SIZE}."},
			{"target": "screen", "wait": "sequence", "text": "You draw back up."},
			{"target": "deck", "wait": "next",
				"text": "Rain of Blood, your Reserve, stayed with you; Fleet Footed waits in the discard pile at its new Level. The Deck grew thinner by the spells you drew."},
		],
	},
	{
		"id": "narrow", "title": "A Narrow Victory", "outcome": "narrow",
		"table": {"phase": "challenge", "region": 1, "deck": ["DOE-A08"], "deck_rest": true,
			"hand": ["DOE-A05", "DOE-A01", "DOE-A09", "DOE-A13"], "discard": [], "trash": []},
		"steps": [
			{"target": "encounter", "wait": "next", "concepts": ["journey"],
				"text": "No foe this time but the High Peaks, a [[journey|Journey]]. You cross it with {icon:move} Move against its {icon:mp} MP. Mountains never strike first, and falling short costs you time - aka, more cards in your deck."},
			{"target": "chip:time", "wait": "next", "concepts": ["time_penalty"],
				"text": "Its [[time|Time Penalty]] is 2: the amount of energy needed for two spells. Less cards means less time to strengthen yourself before facing the dragon."},
			{"target": "place:0/spell", "wait": "next", "concepts": ["enhanced"],
				"text": "Your spells already stand in place. River Swiftness carries you 6 with water, and Brute Force lends the water."},
			{"target": "primary", "wait": "play", "concepts": ["outcomes"],
				"expect": {"spell": "DOE-A09", "element": "DOE-A01", "boost": "DOE-A13", "boost_to": "attack"},
				"hint": "Climb with River Swiftness, Brute Force as Element and Adapt as Boost.",
				"text": "6 and 3 make 9 against 12. Half the MP or more is a [[narrow_victory|Narrow Victory]]: you reach the far side and earn the XP, but lose time on the way. Climb."},
			{"target": "screen", "wait": "sequence", "text": "Over the peaks, barely."},
			{"target": "deck", "wait": "next", "concepts": ["deck_clock"],
				"text": "The narrow victory came at a cost. Two of your spells have been lost for this region. The Deck is your clock, and every spell lost brings the end of this Region nearer."},
			{"target": "xp", "wait": "upgrade", "expect": {}, "concepts": ["cleanup"],
				"text": "Spend the XP on any spell if you like, then confirm."},
		],
	},
	{
		"id": "loss", "title": "A Loss", "outcome": "loss",
		"table": {"phase": "challenge", "region": 1, "deck": ["DOE-A07"], "deck_rest": true,
			"hand": ["DOE-A09", "DOE-A06", "DOE-A15", "DOE-A16"], "discard": [], "trash": []},
		"steps": [
			{"target": "encounter", "wait": "next", "concepts": ["outcomes", "divert"],
				"text": "A Frenzied Ape: 13 HP. Every spell in your Hand is a travelling spell, made for {icon:move} Move, and against a foe a spell whose action does not fit counts only 1. Some fights cannot be won. You may [[divert|Divert]] such a foe, at a cost; here, stand and take the [[loss|Loss]]."},
			{"target": "primary", "wait": "play",
				"expect": {"spell": "DOE-A15", "element": "DOE-A06", "boost": "DOE-A16", "boost_to": "attack"},
				"hint": "Fight with Burning Bridges, Fleet Footed as Element and Motivated Flight as Boost.",
				"text": "Burning Bridges counts 1 and the Boost adds 2: 3, far short of half the ape's 13. Fleet Footed is quicker than the ape, so at least it cannot strike first. Fight."},
			{"target": "screen", "wait": "sequence", "text": "The ape strikes back."},
			{"target": "soak", "wait": "next", "concepts": ["soak"],
				"text": "3 shadow damage. You [[soak|Soak]] it by Downgrading spells in your Hand, as a shield takes a blow."},
			{"target": "hand", "wait": "next", "concepts": ["armor"],
				"text": "Each spell Soaks its {icon:armor} Armor: River Swiftness 2, Fleet Footed 3, Burning Bridges 1, Motivated Flight 2. Armor of the blow's own Ether counts double; none of these is shadow."},
			{"target": "card:DOE-A06", "wait": "soak", "expect": {"picks": ["DOE-A06"]}, "concepts": ["downgrade"],
				"hint": "Let Fleet Footed take the blow.",
				"text": "Fleet Footed's Armor 3 takes the whole blow. Choose it and confirm: it is worn down a Level, a [[downgrade|Downgrade]]."},
			{"target": "screen", "wait": "next", "concepts": ["trash"],
				"text": "A Level 1 spell that is Downgraded is [[trash|Trashed]], lost for the rest of the hunt. Fleet Footed is at Level 1 now: guard it."},
			{"target": "primary", "wait": "upgrade", "expect": {},
				"text": "No XP from a lost fight. Confirm to walk on."},
		],
	},
	{
		"id": "fuse", "title": "Fusing", "outcome": "fuse_complete",
		"table": {"phase": "challenge", "region": 1, "deck": ["DOE-A01"], "deck_rest": true,
			"hand": ["DOE-A03", "DOE-A02", "DOE-A05", "DOE-A09"], "discard": [], "trash": []},
		"steps": [
			{"target": "encounter", "wait": "next",
				"text": "A Crane Monk: 9 HP, with Armor against water. The best Action Set in your Hand falls short."},
			{"target": "card:DOE-A02+DOE-A03", "wait": "next", "concepts": ["fuse"],
				"text": "Sword of Light and Destruction are both water, so they can fuse. Two spells of one Ether [[fuse|Fuse]]: the card selected first becomes the card used, but with a new ether. The bottom card ceases to exist for this hand. Fusing requires a full Hand of 4 cards. Both are lost during Cleanup."},
			{"target": "action:fuse", "wait": "fuse_begin",
				"hint": "Press Fuse.",
				"text": "Press Fuse."},
			{"target": "picker", "wait": "fuse_element",
				"expect": {"top": "DOE-A02", "bottom": "DOE-A03", "element": "fire"},
				"hint": "Fuse Sword of Light over Destruction, as fire.",
				"text": "Choose Sword of Light, then Destruction beneath it, and turn the pair to fire."},
			{"target": "primary", "wait": "play",
				"expect": {"spell": "DOE-A05", "element": "DOE-A02", "boost": "DOE-A09", "boost_to": "attack",
					"fuse": {"top": "DOE-A02", "bottom": "DOE-A03", "element": "fire"}},
				"hint": "Strike with Rain of Blood, the fused Sword of Light as Element and River Swiftness as Boost.",
				"text": "Sword of Light now burns with fire, so Rain of Blood's Attack is enhanced: 8 and 2 make 10 against 9. Strike."},
			{"target": "screen", "wait": "sequence", "text": "The monk falls to a blow no plain Action Set could land."},
			{"target": "primary", "wait": "upgrade", "expect": {}, "concepts": ["cleanup"],
				"text": "Spend the XP if you like, then confirm. Both Fused spells are spent at Cleanup: the Fuse cost you a spell you could have kept."},
		],
	},
	{
		"id": "region_end", "title": "The End of a Region", "outcome": "region_end",
		"table": {"phase": "challenge", "region": 1, "deck": ["DOE-A09", "DOE-A16"],
			"hand": ["DOE-A05", "DOE-A10", "DOE-A13", "DOE-A01"], "discard": "rest", "trash": []},
		"steps": [
			{"target": "deck", "wait": "next", "concepts": ["region_end"],
				"text": "Two spells are left in your Deck. You stay in a Region while your Hand and Deck together can give a fresh Hand and a Key Card: five spells."},
			{"target": "primary", "wait": "play",
				"expect": {"spell": "DOE-A13", "element": "DOE-A10", "boost": "DOE-A01", "boost_to": "attack"},
				"hint": "Cross with Adapt, Rain of Blood as Element and Brute Force as Boost.",
				"text": "The Falls lie ahead. Adapt's Move is enhanced by shadow: 5 and 3 make 8, the MP exactly. Cross."},
			{"target": "screen", "wait": "sequence", "text": "Across the Falls."},
			{"target": "primary", "wait": "upgrade", "expect": {},
				"text": "Confirm. After camp only three spells are left: you have come to the end of the Jade Mountains."},
			{"target": "screen", "wait": "sequence", "text": "The Region ends."},
			{"target": "deck", "wait": "next",
				"text": "Every spell that is not Trashed is gathered and shuffled into a new Deck for the road on."},
			{"target": "screen", "wait": "next",
				"text": "The Living Marshes lie ahead, Region 2, and your spells keep their Levels. Beyond Region 4 Rodving waits, and the Final Battle."},
		],
	},
]

## Shown after the last lesson (contracts/tutorial-flow.md).
const SUMMARY := "You have read the [[key_card|Key Card]], matched Ether for an [[enhanced|enhanced action]], won, scraped through and lost, [[soak|Soaked]] a blow, [[fuse|Fused]] two spells and seen a Region's end. The hunt itself crosses four Regions, then the Final Journey to Rodving's lair and the Final Enemy: the dragon itself. Good hunting."

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
