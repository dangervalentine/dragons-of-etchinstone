extends RefCounted
## The rules of play, as sections of pages, for reading in the game. Written for
## this project and checked against the rulebook: it says what the player decides
## and what the game does for them, never how to handle the cards.
##
## Text may carry three marks, turned into BBCode by expand():
##   [[id]] or [[id|words]]  a Glossary term, shown in bold; in the text, also listed beside it
##   {icon:id}               a game icon, inline at text height
##   {n:NAME}                a number from the engine (see NUMBERS)
##
## A page is {"text": [blocks], "aside": [one block]}. Blocks are {"p": text},
## {"steps": [text]}, {"list": [text]}, {"note": text}, {"table": {"head": [text],
## "rows": [[text]]}} or {"table": "difficulty"}, and {"figure": kind}.

const Glossary = preload("res://ui/model/glossary.gd")
const Game = preload("res://engine/game.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const T = preload("res://ui/theme/tokens.gd")

## Engine numbers the text may name, so it cannot disagree with the rules as played.
const NUMBERS := {
	"HAND_SIZE": Game.HAND_SIZE,
	"FINAL_JOURNEY_HAND": Game.FINAL_JOURNEY_HAND,
	"MAX_DIVERTS": Game.MAX_DIVERTS,
	"KNOCK_OUT_DISCARD": Game.KNOCK_OUT_DISCARD,
}

const CREDIT := "Dragons of Etchinstone is designed by Joe Klipfel and published by Chip Theory Games. The rules belong to them; this is a fan-made digital version, not affiliated with or endorsed by Chip Theory Games."

## Inline icons sit at the height of body text.
const ICON_SIZE := 28

const SECTIONS := [
	{"id": "welcome", "title": "Welcome to Vale", "pages": [
		{"text": [
			{"p": "Dragons have returned to Vale, crawling out of the rifts that Ether magic tears in the land. You are an apprentice mage of the Tower, sent to cross four Regions and hunt one of them down."},
			{"p": "In each Region you face a run of [[enemy|enemies]] and [[journey|Journeys]], using your Mage Cards to fight and to travel. After the fourth Region comes the Final Battle: the Final Journey to reach the dragon, then the Final Enemy, the dragon itself."},
			{"p": "You win if you survive the dragon's last attack. You lose if your Final Journey falls short, if you cannot wound the dragon enough, or if you cannot Soak the damage it deals you."},
		]},
	]},
	{"id": "mage_cards", "title": "Mage Cards", "pages": [
		{"text": [
			{"p": "Your sixteen Mage Cards are your spells, your shield and your clock. Each belongs to one of the four Ethers, shown by its colour and the mark beside its name."},
			{"p": "A card has four [[crown|Levels]], each with its own figures; higher is stronger. Only the current Level counts, and it is the only one drawn; hold a card to see all four. In each step, the figures that matter are lit."},
			{"list": [
				"The strip under the name: the Encounter this card brings as [[key_card|Key Card]], and any Hardship.",
				"{icon:initiative} Initiative: your speed when it is the Element.",
				"Basic and [[enhanced|enhanced action]]: the Attack or Move it gives as the Spell.",
				"{icon:boost} Boost, {icon:armor} Armor and the {icon:xp} XP cost of its next Level.",
			]},
		], "aside": [
			{"figure": "mage"},
		]},
		{"text": [
			{"p": "Levels change all game. Spending XP [[upgrade|Upgrades]] a card; taking damage [[downgrade|Downgrades]] one. A Level 1 card that is Downgraded is [[trash|Trashed]] and gone for good."},
			{"p": "The card on top of your [[deck|Deck]] is the [[key_card|Key Card]]. Its strip decides your next Encounter, so the same card can be a fine spell in your Hand and a nasty fight on top of the Deck."},
			{"note": "Hover a card to see every figure spelled out, hold it to see its other Levels, and press any figure in play to have it explained."},
		]},
	]},
	{"id": "regions", "title": "Regions and Encounters", "pages": [
		{"text": [
			{"p": "Your road crosses four Regions in order. Each has four [[enemy|enemies]] and four [[journey|Journeys]] of its own, numbered 1 to 4, and every Region is harder than the one before."},
			{"p": "The Key Card names the Encounter, an enemy or a Journey and its number, and you meet that one in the Region you are in."},
			{"list": [
				"An enemy shows {icon:hp} HP, {icon:initiative} Initiative, {icon:attack} Attack and {icon:armor} Armor.",
				"A Journey shows {icon:mp} MP and a {icon:time} [[time|Time Penalty]].",
				"Both show the {icon:xp} [[xp|XP]] they are worth, and some carry an Ability or a Peril.",
			]},
		], "aside": [
			{"figure": "enemy"},
		]},
	]},
	{"id": "dragons", "title": "The Dragons", "pages": [
		{"text": [
			{"p": "Four dragons wait at the end of the road. You choose which one to hunt before you set out, and each fights in its own way."},
			{"list": [
				"{icon:initiative} Initiative and [[early_damage|Early Damage]]: be faster, or take this damage too.",
				"{icon:armor} Armor against up to three Ethers, which blunts your enhanced Attacks of those Ethers.",
				"Three {icon:mp} MP tiers for the Final Journey, each with the time it costs.",
				"Three {icon:hp} HP tiers for the Final Enemy, each with the damage it hits back with.",
			]},
			{"p": "Reaching a higher tier always costs you less. The dragon screen shows all of these, so compare the dragons before you choose."},
		], "aside": [
			{"figure": "dragon"},
		]},
	]},
	{"id": "setup", "title": "Starting a Game", "pages": [
		{"text": [
			{"p": "Setting out takes two screens. On the first you pick your dragon. On the second you pick a difficulty and, if you like, the alternate rules described in the last section."},
			{"p": "Every card starts at Level 2. Some difficulties raise or lower a few: the game draws cards from your Deck and you choose which ones change. Where every drawn card changes, there is nothing to choose."},
			{"note": "The game shuffles the Deck, deals your first Hand of {n:HAND_SIZE} cards and sets out Region 1 for you."},
			{"p": "Then your first Encounter begins."},
		]},
	]},
	{"id": "encounter", "title": "An Encounter", "pages": [
		{"text": [
			{"p": "A Region is a string of Encounters, and every Encounter passes through the same five phases. When one Encounter ends the next begins, until your Deck runs low and the Region is over."},
			{"p": "The game moves you from phase to phase and stops only when it needs a decision from you."},
		], "aside": [
			{"table": {"head": ["Phase", "What happens"], "rows": [
				["Challenge", "See what you face; you may [[divert|Divert]]."],
				["Action", "Build your [[action_set|Action Set]] and see the result."],
				["Penalty", "Lose time and [[soak|Soak]] damage."],
				["Upgrade", "Spend the XP you earned."],
				["Cleanup", "Discard and draw back up."],
			]}},
		]},
	]},
	{"id": "challenge", "title": "Challenge Phase", "pages": [
		{"text": [
			{"p": "The game reveals the Encounter named by the [[key_card|Key Card]] and shows its figures."},
			{"p": "The Key Card may also bring a Hardship, which makes this one Encounter harder. The table lists all four."},
			{"p": "Before you commit, you may [[divert|Divert]]: give up one card from your Hand, and the Key Card goes to the discard pile, revealing a new one."},
		], "aside": [
			{"table": {"head": ["Hardship", "Effect"], "rows": [
				["{icon:ambush} [[ambush]]", "Early Damage is doubled."],
				["{icon:hazards} [[hazards]]", "Early Damage and Combat Damage each cost 1 time as well."],
				["{icon:night_travel} [[night_travel]]", "Boost is cut by your Initiative, to no less than 0."],
				["{icon:storm} [[storm]]", "Every Time Penalty also deals that much damage."],
			]}},
		]},
		{"text": [
			{"p": "You may Divert up to {n:MAX_DIVERTS} times before you face an Encounter, as long as the Deck holds another Key Card to turn to."},
			{"p": "It has a price. You face the next Encounter with a smaller Hand, and the two discarded cards bring the end of the Region closer, leaving fewer Encounters in which to earn XP."},
			{"note": "Divert when an Encounter is one you cannot win and losing it would hurt more than a weaker Hand."},
		]},
	]},
	{"id": "action", "title": "Action Phase", "pages": [
		{"text": [
			{"p": "Now build your [[action_set|Action Set]] by giving three cards in your Hand a Role each."},
			{"list": [
				"[[spell|Spell]]: its action is what you do, {icon:attack} Attack to fight an enemy or {icon:move} Move to cross a Journey.",
				"[[element_role|Element]]: lends its Ether and its {icon:initiative} Initiative.",
				"[[boost_role|Boost]]: adds its {icon:boost} Boost.",
			]},
			{"p": "If the Element's Ether matches the Spell's [[enhanced|enhanced action]], you get the enhanced value; if not, the basic one."},
			{"p": "The card left out is your [[reserve|Reserve]]. It stays in your Hand for the next Encounter."},
		]},
		{"text": [
			{"p": "Your Hand is held in the rulebook's order, from the left: Reserve, Element, Spell, Boost. The Hand is dealt into those places in the order it was drawn; tap two cards, or drag one onto another, to swap their Roles. Against an Enemy, tap Attack or Initiative in the box under the Encounter to add the Boost there."},
			{"p": "A Spell whose actions do not suit the Encounter still counts, at a value of 1. Actions marked with both the Attack and the Move icon work as either."},
			{"p": "With fewer than three cards in your Hand, as after a Divert, fill the Roles you can; one of them must be the Spell."},
			{"p": "Without an Element your Initiative is 0, apart from any Boost you put into it."},
		]},
		{"text": [
			{"p": "Once per Encounter you may [[fuse|Fuse]] two cards of the same Ether into one. The top card fills a Role as usual but counts as any Ether you choose; the other card fills no Role and is not your Reserve."},
			{"p": "You need a full Hand to Fuse, and both cards are discarded at Cleanup, so it costs you a card you could have kept."},
			{"p": "When the Encounter ends the pair comes apart, so each card takes damage and Upgrades on its own."},
			{"note": "Picking the fused card's Ether can turn an ordinary Element into the key to a Spell's enhanced action."},
		]},
	]},
	{"id": "enemies", "title": "Fighting an Enemy", "pages": [
		{"text": [
			{"steps": [
				"Choose where your [[boost_role|Boost]] goes: to {icon:initiative} Initiative to strike first, or to {icon:attack} Attack to strike harder.",
				"If the enemy's Initiative beats yours, you will take its Attack as [[early_damage|Early Damage]].",
				"Your Attack is the Spell's enhanced Attack if the Element's Ether matches it, otherwise its basic Attack.",
				"If the enemy has {icon:armor} Armor of the same Ether as your enhanced Attack, it is taken off.",
			]},
			{"p": "Then your Attack is measured against the enemy's {icon:hp} HP. Combat Damage is the enemy's Attack, taken in the Penalty Phase."},
		], "aside": [
			{"table": {"head": ["Your Attack", "Result"], "rows": [
				["HP or more", "[[victory]]: earn its XP."],
				["Half the HP or more, rounded up", "[[narrow_victory]]: earn its XP, but take its Combat Damage."],
				["Less than half", "[[loss]]: take its Combat Damage."],
			]}},
		]},
		{"text": [
			{"p": "Some enemies have an Ability, shown on the Encounter. The table lists all four."},
			{"p": "Poison damage on your next Hand must be Soaked as soon as it is drawn. If no new Hand will be drawn in this Region, it is added to the damage you take now."},
			{"p": "Against a Ranged enemy you decide while building your Action Set whether to give up your Reserve. It spares you the Early Damage but costs you the card you would have kept."},
		], "aside": [
			{"table": {"head": ["Ability", "Effect"], "rows": [
				["{icon:freeze} [[freeze]]", "If it deals Early Damage, your Reserve is discarded at Cleanup."],
				["{icon:poison} [[poison]]", "Each time it hurts you, early or in combat, your next Hand in this Region takes 1 more damage."],
				["{icon:ranged} [[ranged]]", "Deals Early Damage even if you are faster, unless you give up your Reserve."],
				["{icon:slow} [[slow]]", "You may use your Move against its HP instead of your Attack."],
			]}},
		]},
	]},
	{"id": "journeys", "title": "Making a Journey", "pages": [
		{"text": [
			{"steps": [
				"Your {icon:move} Move is the Spell's enhanced Move if the Element's Ether matches it, otherwise its basic Move.",
				"Your {icon:boost} Boost always adds to your Move.",
				"If you make an enhanced Move of the same Ether as the Journey's {icon:mp} MP, your [[reserve|Reserve]] card's Boost adds as well.",
			]},
			{"p": "Journeys have no Initiative and no Early Damage."},
		], "aside": [
			{"figure": "journey"},
		]},
		{"text": [
			{"p": "Your Move is measured against the Journey's {icon:mp} MP, as the table shows."},
			{"p": "A [[time|Time Penalty]] does not hurt your cards; it costs you time. The Penalty Phase explains how."},
		], "aside": [
			{"table": {"head": ["Your Move", "Result"], "rows": [
				["MP or more", "[[victory]]: earn its XP."],
				["Half the MP or more, rounded up", "[[narrow_victory]]: earn its XP, but take its Time Penalty."],
				["Less than half", "[[loss]]: take its Time Penalty."],
			]}},
		]},
		{"text": [
			{"p": "Some Journeys have a Peril, shown on the Encounter. The table lists both."},
			{"p": "Damage from a Journey has no Ether, so Armor never doubles against it."},
		], "aside": [
			{"table": {"head": ["Peril", "Effect"], "rows": [
				["{icon:steep} [[steep]]", "The MP rises by your Reserve card's Boost."],
				["{icon:treacherous} [[treacherous]]", "Without a Complete Victory you take 1 damage on top of the Time Penalty."],
			]}},
		]},
	]},
	{"id": "penalty", "title": "Penalty Phase", "pages": [
		{"text": [
			{"p": "Everything that went wrong in the Encounter is added up and settled at once: Early Damage, Combat Damage, Time Penalties and any extra damage from Hardships, Abilities and Perils."},
			{"p": "{icon:time} [[time|Time Penalties]] come first. For each point the game discards the top card of your Deck, bringing the end of the Region closer. If the Deck runs dry, each card it could not discard becomes 1 damage."},
			{"p": "Then the damage. You [[soak|Soak]] it by choosing cards in your Hand to [[downgrade|Downgrade]]."},
		]},
		{"text": [
			{"list": [
				"Each card Soaks its {icon:armor} Armor, or double that if the Armor's Ether matches the damage. Armor without an Ether never doubles.",
				"A card can be Downgraded only once per Encounter. Choose only as many cards as the damage needs.",
				"A Level 1 card that is Downgraded is [[trash|Trashed]] for the rest of the game.",
			]},
			{"p": "If your whole Hand cannot Soak the damage, you are [[knock_out|Knocked Out]]: every card not yet Downgraded is Downgraded, and the game discards {n:KNOCK_OUT_DISCARD} cards from your Deck. Then play goes on."},
		]},
	]},
	{"id": "upgrade_cleanup", "title": "Upgrade and Cleanup", "pages": [
		{"text": [
			{"p": "If you earned XP, spend it now to [[upgrade|Upgrade]] cards in your Hand, a Level at a time. Each Upgrade costs the {icon:xp} XP shown on that card."},
			{"list": [
				"Your Reserve and Fused cards can be Upgraded too, and a card can go up more than once.",
				"A card Downgraded this Encounter cannot be Upgraded.",
				"XP cannot be saved: whatever you leave unspent is lost.",
			]},
			{"p": "Then Cleanup. Your Action Set is discarded, and your Reserve stays in your Hand unless Freeze or Ranged took it."},
			{"note": "The game draws you back up to {n:HAND_SIZE} cards. Until you finish, Undo takes back an Upgrade."},
		]},
	]},
	{"id": "region_end", "title": "End of a Region", "pages": [
		{"text": [
			{"p": "A Region lasts until your Deck can no longer give you a fresh Hand and a Key Card: when your Hand and Deck together hold fewer than five cards after Cleanup, the Region ends."},
			{"note": "The game gathers every card that is not Trashed, shuffles them into a new Deck, deals your Hand and sets out the next Region. Cards keep their Levels."},
			{"p": "Trashed cards never come back."},
			{"p": "After Region 4 the Final Battle begins. If so many cards are Trashed that a new Region could not even be dealt, you go straight to the Final Battle."},
		]},
	]},
	{"id": "final_journey", "title": "The Final Journey", "pages": [
		{"text": [
			{"p": "The Final Battle starts with a fresh Deck of every card you still have. First comes the Final Journey, to reach the dragon."},
			{"p": "You draw {n:FINAL_JOURNEY_HAND} cards and build two Action Sets, each with a Spell, an Element and a Boost. One card may be left over as your Reserve, and you may Fuse only once across both sets."},
			{"p": "The two Moves are added together. If either set makes an enhanced Move of the same Ether as the dragon's {icon:mp} MP, your Reserve's Boost is added once."},
			{"note": "The game shuffles your cards and sets out the dragon for you."},
		], "aside": [
			{"table": {"head": ["Total Move", "Result"], "rows": [
				["Below the first tier", "You lose at once."],
				["First tier", "Lose the first tier's time."],
				["Second tier", "Lose the second tier's time."],
				["Third tier", "Lose the third tier's time."],
			]}},
		]},
		{"text": [
			{"p": "Once per game, before you commit, you may [[regroup|Regroup]]: discard one card and draw a new Hand of {n:FINAL_JOURNEY_HAND}. The game slips the rest of your old Hand under your Deck."},
			{"p": "Afterwards all your Final Journey cards are discarded, and every card left in the Deck becomes your Hand for the Final Enemy."},
			{"p": "If the Deck cannot pay all of the time you lose, the rest is added to the damage the dragon deals you."},
		]},
	]},
	{"id": "final_enemy", "title": "The Final Enemy", "pages": [
		{"text": [
			{"p": "Now you face the dragon. Build two Action Sets from your Hand again, this time to Attack; each set's Boost goes to its own Attack or Initiative. A set with fewer than three cards still needs a Spell."},
			{"steps": [
				"If your two Initiatives together fall short of the dragon's, you will also take its [[early_damage|Early Damage]].",
				"Your two Attacks are added together. For each Ether of your enhanced Attacks that the dragon's {icon:armor} Armor guards against, that Armor is taken off once.",
				"What is left is measured against the dragon's {icon:hp} HP tiers.",
			]},
		], "aside": [
			{"table": {"head": ["Total Attack", "Result"], "rows": [
				["Below the first tier", "You lose at once."],
				["First tier", "Take the first tier's damage."],
				["Second tier", "Take the second tier's damage."],
				["Third tier", "Take the third tier's damage."],
			]}},
		]},
		{"text": [
			{"p": "Last, survive. The dragon's damage, any Early Damage and anything carried over from the Final Journey are added up, and you must [[soak|Soak]] the total with your Hand."},
			{"p": "Every card in your Hand can help, each Downgraded once. The dragon's damage has its Ether, so matching Armor doubles."},
			{"p": "Soak it all and the dragon is slain: you win. Fall short and the dragon wins."},
		]},
	]},
	{"id": "scoring", "title": "Scoring", "pages": [
		{"text": [
			{"p": "You can play simply to win, or keep score as well."},
			{"p": "A loss scores 0. A win scores the total of the Levels of every card that was not Trashed, counted after you Soak the dragon's last attack."},
			{"p": "So a high score means keeping your cards strong to the very end: Upgrade whenever you can, and choose carefully what you Downgrade."},
			{"p": "Every game you play is kept. The Leaderboard, on the first screen and in the menu, shows your best wins on each difficulty, which you can narrow to one dragon; the History, in the menu, lists every attempt with how far it got."},
		]},
	]},
	{"id": "ethers", "title": "The Four Ethers", "pages": [
		{"text": [
			{"list": [
				"{icon:water} [[water]]: very strong Armor and Initiative; standard Attack, Boost and Move.",
				"{icon:fire} [[fire]]: very strong Attack; weak Armor, Boost, Initiative and Move.",
				"{icon:lightning} [[lightning]]: very strong Move and strong Initiative; weak Attack and Boost; costly to Upgrade.",
				"{icon:shadow} [[shadow]]: very strong Boost; standard Attack, Initiative and Move. The actions that work as Attack or Move are enhanced by Shadow.",
			]},
			{"p": "Ether matters in four places: a Spell's enhanced action, enemy and dragon Armor, your own Armor against damage, and a Journey's MP."},
		]},
	]},
	{"id": "difficulty", "title": "Difficulty and Alternate Rules", "pages": [
		{"text": [
			{"p": "You choose the difficulty on the second setup screen. It sets the starting Level of a few cards: the game draws the number shown, and you choose which of them change, unless all of them do."},
			{"p": "Two alternate rules sit on the same screen. Use either, both or neither:"},
			{"list": [
				"Cavalier: you cannot [[fuse|Fuse]].",
				"Glass Cannon: Armor whose Ether matches the damage Soaks just 1 extra instead of double.",
			]},
		], "aside": [
			{"table": "difficulty"},
		]},
	]},
]

## Where the reader is, kept while the game runs and forgotten when it closes.
static var position := {"section": 0, "page": 0}

static var _term_re: RegEx
static var _icon_re: RegEx
static var _number_re: RegEx


static func section_count() -> int:
	return SECTIONS.size()


static func page_count(section: int) -> int:
	return SECTIONS[section].pages.size()


## The index of the section with this id, or -1.
static func find(section_id: String) -> int:
	for i in SECTIONS.size():
		if SECTIONS[i].id == section_id:
			return i
	return -1


## The page `delta` (1 or -1) away, crossing into the next or previous section.
## At either end of the book the position is returned unchanged.
static func step(pos: Dictionary, delta: int) -> Dictionary:
	var s: int = pos.section
	var p: int = pos.page + delta
	if p >= page_count(s):
		if s + 1 >= section_count():
			return pos
		return {"section": s + 1, "page": 0}
	if p < 0:
		if s == 0:
			return pos
		return {"section": s - 1, "page": page_count(s - 1) - 1}
	return {"section": s, "page": p}


## A page ready to draw: every string expanded, and the Glossary terms it marks.
static func page(section: int, page_index: int) -> Dictionary:
	var raw: Dictionary = SECTIONS[section].pages[page_index]
	return {
		"text": _expand_all(raw.get("text", [])),
		"aside": _expand_all(raw.get("aside", [])),
		"terms": terms(section, page_index),
	}


## The Glossary ids marked in a page's text, first use first, each once. Terms
## inside the aside are explained by the aside itself, so they are not listed.
static func terms(section: int, page_index: int) -> Array:
	var strings := []
	_collect(SECTIONS[section].pages[page_index].get("text", []), strings)
	return terms_in(strings)


## The Glossary ids marked in these strings, first use first, each once.
static func terms_in(strings: Array) -> Array:
	_compile()
	var out := []
	for s in strings:
		for m in _term_re.search_all(s):
			var id := m.get_string(1)
			if not out.has(id):
				out.append(id)
	return out


## Marks to BBCode: bold terms, inline icons and engine numbers.
static func expand(text: String) -> String:
	_compile()
	var out := text
	for m in _term_re.search_all(text):
		var words: String = m.get_string(2) if m.get_string(2) != "" else Glossary.entry(m.get_string(1)).name
		out = out.replace(m.get_string(0), "[b]%s[/b]" % words)
	for m in _icon_re.search_all(text):
		var id := m.get_string(1)
		var colour: Color = T.ETHER.get(id, T.GOLD)
		out = out.replace(m.get_string(0), "[img width=%d height=%d color=#%s]res://art/icons/%s.svg[/img]" % [ICON_SIZE, ICON_SIZE, colour.to_html(false), id])
	for m in _number_re.search_all(text):
		out = out.replace(m.get_string(0), str(NUMBERS.get(m.get_string(1), m.get_string(0))))
	return out


## The difficulty table, from the engine's own settings.
static func difficulty_rows() -> Array:
	var out := []
	for id in Game.DIFFICULTY:
		var d: Array = Game.DIFFICULTY[id]
		out.append({"id": id, "name": ViewState.DIFFICULTY_NAMES.get(id, id.capitalize()),
			"offered": d[0], "changed": d[1], "level": d[2]})
	return out


static func _compile() -> void:
	if _term_re != null:
		return
	_term_re = RegEx.create_from_string("\\[\\[([a-z_]+)(?:\\|([^\\]]+))?\\]\\]")
	_icon_re = RegEx.create_from_string("\\{icon:([a-z_]+)\\}")
	_number_re = RegEx.create_from_string("\\{n:([A-Z_]+)\\}")


static func _expand_all(blocks: Array) -> Array:
	var out := []
	for b in blocks:
		out.append(_expand_value(b))
	return out


static func _expand_value(v):
	if v is String:
		return expand(v)
	if v is Array:
		return v.map(func(x): return _expand_value(x))
	if v is Dictionary:
		var d := {}
		for k in v:
			# A figure or a generated table names a kind; it is not text.
			d[k] = v[k] if k == "figure" or (k == "table" and v[k] is String) else _expand_value(v[k])
		return d
	return v


static func _collect(v, out: Array) -> void:
	if v is String:
		out.append(v)
	elif v is Array:
		for x in v:
			_collect(x, out)
	elif v is Dictionary:
		for k in v:
			_collect(v[k], out)
