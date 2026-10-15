extends RefCounted
## Short explanations of every icon, effect and game term, shown on demand.
## Written for this project and checked against the rulebook. `short` is the
## one-line form shown on an Encounter; `text` is the full explanation.

const ENTRIES := {
	# Encounter figures
	"hp": {"name": "HP", "icon": "hp", "text": "The enemy's health. Match it with your Attack for a Complete Victory; reach half for a Narrow Victory."},
	"initiative": {"name": "Initiative", "icon": "initiative", "text": "Speed. If the enemy's Initiative is higher than yours, it deals Early Damage before you strike."},
	"attack": {"name": "Attack", "icon": "attack", "text": "Your Spell's strength against an enemy, compared with its HP. On an enemy, it is the damage the enemy deals."},
	"move": {"name": "Move", "icon": "move", "text": "Your Spell's reach on a Journey, compared with the Journey's MP."},
	"mp": {"name": "MP", "icon": "mp", "text": "The distance a Journey asks for. Match it with your Move for a Complete Victory; reach half for a Narrow Victory."},
	"time": {"name": "Time Penalty", "icon": "time", "text": "Discard this many cards from the top of your deck. Fewer cards means fewer Encounters before the dragon."},
	"xp": {"name": "XP", "icon": "xp", "text": "Earned by winning an Encounter and spent at once to Upgrade cards in your Hand. Unspent XP is lost."},
	"armor": {"name": "Armor", "icon": "armor", "text": "On an enemy, Armor reduces an enhanced Attack of the matching Ether. On your cards, Armor is how much damage the card Soaks when Downgraded, doubled against damage of its own Ether."},
	"boost": {"name": "Boost", "icon": "boost", "text": "The amount a card adds when played in the Boost role. Against an enemy you choose whether it adds to Attack or to Initiative."},
	"crown": {"name": "Level", "icon": "crown", "text": "A card's Level, from 1 to 4. Upgrading raises it, Soaking damage lowers it, and your score is the total of your cards' Levels."},
	# Ethers
	"fire": {"name": "Fire", "icon": "fire", "text": "One of the four Ethers. A Spell uses its stronger, enhanced action when the Element card supplies the Ether it asks for."},
	"water": {"name": "Water", "icon": "water", "text": "One of the four Ethers. A Spell uses its stronger, enhanced action when the Element card supplies the Ether it asks for."},
	"lightning": {"name": "Lightning", "icon": "lightning", "text": "One of the four Ethers. A Spell uses its stronger, enhanced action when the Element card supplies the Ether it asks for."},
	"shadow": {"name": "Shadow", "icon": "shadow", "text": "One of the four Ethers. A Spell uses its stronger, enhanced action when the Element card supplies the Ether it asks for."},
	# Encounter kinds
	"enemy": {"name": "Enemy", "icon": "enemy", "text": "An Encounter you fight. Compare your Attack with its HP and your Initiative with its Initiative."},
	"journey": {"name": "Journey", "icon": "journey", "text": "An Encounter you travel. Compare your Move with its MP; falling short costs a Time Penalty."},
	# Hardships
	"ambush": {"name": "Ambush", "icon": "ambush", "short": "Early Damage is doubled", "text": "A Hardship from the Key Card. Any Early Damage you suffer in this Encounter is doubled."},
	"hazards": {"name": "Hazards", "icon": "hazards", "short": "Being hit also costs time", "text": "A Hardship from the Key Card. Suffer 1 Time Penalty if you take Early Damage and 1 more if you take Combat Damage."},
	"night_travel": {"name": "Night Travel", "icon": "night_travel", "short": "Boost is reduced by Initiative", "text": "A Hardship from the Key Card. Your Boost is reduced by your Initiative, to no less than 0."},
	"storm": {"name": "Storm", "icon": "storm", "short": "Time Penalties also deal damage", "text": "A Hardship from the Key Card. If you suffer a Time Penalty in this Encounter, you also suffer that much damage."},
	# Enemy abilities
	"freeze": {"name": "Freeze", "icon": "freeze", "short": "Early Damage discards your Reserve", "text": "If this enemy deals Early Damage, your Reserve card is discarded at the end of the Encounter instead of being kept."},
	"poison": {"name": "Poison", "icon": "poison", "short": "Damage poisons your next Hand", "text": "Each time this enemy damages you, early or in combat, 1 extra damage lands on the next Hand you draw in this Region."},
	"ranged": {"name": "Ranged", "icon": "ranged", "short": "Strikes first unless you give up your Reserve", "text": "This enemy deals Early Damage even if you beat its Initiative. You can ignore that by giving up your Reserve card, which is then discarded."},
	"slow": {"name": "Slow", "icon": "slow", "short": "You may Move instead of Attack", "text": "You may compare your Move with this enemy's HP instead of your Attack."},
	# Journey perils
	"steep": {"name": "Steep", "icon": "steep", "short": "MP rises by your Reserve's Boost", "text": "The Journey's MP is increased by the Boost of your Reserve card."},
	"treacherous": {"name": "Treacherous", "icon": "treacherous", "short": "1 damage unless you win outright", "text": "Unless you win a Complete Victory, you suffer 1 damage as well as the Journey's Time Penalty."},
	# Piles
	"deck": {"name": "Deck", "icon": "deck", "text": "Your undrawn cards. The top card is the Key Card, which sets the Encounter. A Region ends when too few cards remain for another Hand."},
	"discard": {"name": "Discard", "icon": "discard", "text": "Cards played or lost to Time Penalties. They are shuffled back into the deck at the start of the next Region."},
	"trash": {"name": "Trash", "icon": "trash", "text": "Cards removed from the game. A Level 1 card that is Downgraded is Trashed and no longer counts toward your score."},
	# Roles and terms
	"key_card": {"name": "Key Card", "icon": "deck", "text": "The top card of your deck. It names the Encounter you face and may add a Hardship."},
	"action_set": {"name": "Action Set", "icon": "spell", "text": "Three cards from your Hand, one each as Spell, Element and Boost. The fourth card is your Reserve."},
	"spell": {"name": "Spell", "icon": "spell", "text": "The card whose action you use. It gives its enhanced action if the Element card supplies the right Ether and the action suits the Encounter; otherwise its basic action."},
	"element_role": {"name": "Element", "icon": "element_role", "text": "The card that supplies its Ether to the Spell and its Initiative to the Action Set."},
	"boost_role": {"name": "Boost role", "icon": "boost", "text": "The card that adds its Boost to the Action Set."},
	"reserve": {"name": "Reserve", "icon": "reserve", "text": "The Hand card left out of the Action Set. It is kept for the next Hand, and on a Journey its Boost adds to your Move when your enhanced Ether matches the Journey's."},
	"enhanced": {"name": "Enhanced action", "icon": "spell", "text": "A Spell's stronger action, shown on a coloured plate. It needs the Element card to supply the Ether of that colour."},
	"fuse": {"name": "Fuse", "icon": "fuse", "text": "Tuck one card behind another of the same Ether. The top card then counts as any Ether you choose; the tucked card fills no role and is discarded afterwards."},
	"divert": {"name": "Divert", "icon": "divert", "text": "Discard the Key Card and one card from your Hand to face the next Key Card instead. Up to twice per Encounter."},
	"regroup": {"name": "Regroup", "icon": "regroup", "text": "Once, on the Final Journey: discard one card, shuffle the rest of your Hand back into the deck and draw again."},
	"soak": {"name": "Soak", "icon": "armor", "text": "Absorb damage by Downgrading cards in your Hand. Each card Soaks its Armor, doubled if the Armor's Ether matches the damage."},
	"downgrade": {"name": "Downgrade", "icon": "down_arrow", "text": "Lower a card by one Level. A card can be Downgraded once per Encounter and cannot be Upgraded in the same Encounter. At Level 1 it is Trashed."},
	"upgrade": {"name": "Upgrade", "icon": "crown", "text": "Spend XP to raise a card in your Hand by one Level. The cost is shown beside the upgrade star on the card."},
	"knock_out": {"name": "Knock Out", "icon": "down_arrow", "text": "If your Hand cannot Soak all the damage, every card in it is Downgraded and four cards are discarded from your deck."},
	"victory": {"name": "Complete Victory", "icon": "victory", "text": "You matched the target. You earn the XP and take no Combat Damage or Time Penalty."},
	"narrow_victory": {"name": "Narrow Victory", "icon": "narrow_victory", "text": "You reached at least half the target. You earn the XP but still take the Combat Damage or Time Penalty."},
	"loss": {"name": "Loss", "icon": "loss", "text": "You fell short of half the target. You earn no XP and take the Combat Damage or Time Penalty."},
	"early_damage": {"name": "Early Damage", "icon": "initiative", "text": "Damage an enemy deals before you strike, when its Initiative is higher than yours. It is added to any Combat Damage."},
	"fused": {"name": "Fused", "icon": "fuse", "text": "This card has another tucked behind it and counts as the Ether shown on its badge."},
}

## Icons that are decoration or controls, not game symbols, and need no entry.
const NOT_SYMBOLS := ["menu", "settings", "help", "skip", "close", "inspect", "card_back", "down_arrow", "undo", "book"]


static func has(id: String) -> bool:
	return ENTRIES.has(id)


static func entry(id: String) -> Dictionary:
	var e: Dictionary = ENTRIES.get(id, {"name": id.capitalize(), "icon": "", "text": ""})
	return {"id": id, "name": e.name, "icon": e.get("icon", ""), "text": e.text, "short": e.get("short", "")}


## Every entry, in reading order, for the full glossary.
static func all() -> Array:
	return ENTRIES.keys().map(func(id): return entry(id))
