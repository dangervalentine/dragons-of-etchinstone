# Idea Intake: Card contribution highlights replace the outcome math box

- **Slug**: card-contribution-highlights
- **Created**: 2026-10-17
- **Source**: pasted text (relates to the Hand / math box / action row shipped in `specs/010-legible-hand-cards`, commit `c47ffa9`)
- **Type**: improvement

## Idea (as captured)

> we are no longer going to show the intended outcome of the damage, initiative, ect... in the bottom left. instead, when a card is in a given position, highlight the parts of the card which will contribute to the outcome when the user hits 'play' boost highlights for the right most card. enhanced action is highlighted when a card in the spell slot is active and the ether position is filled with the right card. ect... if a user is facing a journey which has a hardship that takes a value from their cards to make the journey harder - apply another highlight to that card - instead of a border around the badge - the text hcnages color or something. we are not going to show the intended outcome for user's anymore, they can figure out if they have it or not. ranged enemies cause the reserve card to show this impacted state until they elect to give up their reserve.  this will open the enemy left hand column as we won't show these numbers there any longer. either add a 'boost [attack|initiative]' button in the bottom row - adjusting the size of the 'play' button to include this or add a button directly on the card in the boost slot near the boost badge which would change how it is applied. take these parts out of the left column and leave it empty. we are updating it in a follow up spec

## Restated

Stop showing the predicted outcome (damage, Initiative, etc.) in the bottom-left math box. Instead, on each card placed in the Hand, highlight the specific parts that will feed the result when Play is pressed (e.g. the Boost on the rightmost card; the enhanced action when the Spell is active and the Element/"ether" place holds a matching card), and mark parts that a Journey Hardship or a Ranged Enemy will draw against with a distinct "impacted" style (text colour change rather than a badge border). Because the math box's Attack/Initiative rows currently aim the Boost, that control moves either into the action row as a "Boost [Attack|Initiative]" button or onto the Boost card near its badge; the left column is left empty for a follow-up spec.

### Owner clarifications (2026-10-17, after research)

> the enemy panel's on the left of their image, and the journey's values stay. I was saying the player's predicted values and outcomes are not spelt out below the enemy cards any longer. earlier specs were the result of continued iteration - normal software development. soak meter and xp purse will stay. this change will include a change to them though, xp will be a collection of stars which will deplete as the user uses them - using 3 out of 8 causes 3 stars to travel to the card in question as the card levels up. leaving them behind causes them to fade out

- Only the **player's** predicted values and outcome (the math box under the Encounter) go. The Enemy's stats panel beside its image and the Journey's values stay.
- The soak meter and XP purse stay in the left column, but the XP purse changes. XP shows as a row of stars that deplete as XP is spent: spending 3 of 8 sends 3 stars to the card being levelled. Stars left unspent fade out, matching the rule "Excess XP is lost at the end of [the] Encounter" (reference/rulebook.txt:790).

## Origin & Context

- **Raised by**: the project owner (Danger Valentine)
- **Trigger**: freeing the math box's space for a follow-up left-column pass without breaking current functionality (owner, 2026-10-17). It follows spec 010, which made the math box the place values are read and the Boost is aimed, so those jobs have to move onto the cards first. It is not motivated by hiding the outcome from players.

## First-Glance Unknowns

- [NEEDS CLARIFICATION: Full list of card parts and the conditions under which each counts as "contributing" (the input ends in "ect…" — beyond Boost and enhanced action, which others: Element value, Spell base action, Key Card part, Final Battle sets?)]
- [NEEDS CLARIFICATION: What "ether position" refers to in current terms — the Element place? — and what "the right card" means (matching Element, Level, other)?]
- [NEEDS CLARIFICATION: Which Hardships "take a value from their cards" and exactly which part of which card is marked as impacted]
- [NEEDS CLARIFICATION: Visual language for "contributing" vs "impacted" highlights — colour, glow, text colour — and how they stay distinct from existing badge borders and lifted/selected states, including colour-blind legibility]
- [NEEDS CLARIFICATION: Ranged Enemy: is the whole Reserve card impacted or a specific part, and what changes once the Reserve is given up?]
- [NEEDS CLARIFICATION: Boost aiming control — action-row button (how it shares width with Fuse, Divert, Give up Reserve, Play) or an on-card toggle near the Boost badge? What is the default aim, and does it apply outside Enemy encounters?]
- ~~Does "no intended outcome" also remove Enemy-side numbers?~~ Resolved: Enemy panel and Journey values stay; only the player's predicted values and outcome go.
- ~~Does the left column empty fully?~~ Resolved: soak meter and XP purse stay; only the math box leaves.
- [NEEDS CLARIFICATION: XP stars — how many stars per XP point, how a large purse fits, and do the stars fly when spent one level at a time or on commit?]
- [NEEDS CLARIFICATION: Impact on the rules engine / tests that currently feed the math box — is the computed outcome kept internally (e.g. for highlights) or removed?]
