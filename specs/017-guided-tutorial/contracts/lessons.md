# Contract: The Six Lessons

The outline of every lesson, step by step: what is lit, what the player must do, and
which FR-012 concepts the step covers. The final wording is written in
`ui/model/lessons.gd` during implementation, in this project's own words and with
`[[term]]` Glossary links. The figures quoted come from research R1 and are proved by
`tests/test_lessons.gd`.

Step notation: **target** · *wait* · concepts.

As built: a *sequence* step shows no mark while its animation plays, so a message about
what the animation showed is a read step after it (the `3b`/`4b` steps below). The exact
wording lives in `ui/model/lessons.gd`.

## Concept ids (FR-012)

`deck`, `key_card`, `hardship`, `ether`, `enhanced`, `roles`, `reserve`, `enemy_figures`,
`initiative`, `outcomes`, `journey`, `time_penalty`, `deck_clock`, `region_end`, `soak`,
`armor`, `downgrade`, `trash`, `upgrade`, `unspent_xp`, `cleanup`, `fuse`, `divert`.

Every id must be listed by at least one step; `test_lessons` checks this (SC-004).

## Lesson 1: Setting out (`setting_out`)

1. **screen** · *next*: Welcome. You are a mage hunting a dragon across four Regions;
   these lessons teach one idea each.
2. Dragon screen, **Rodving's tile** · *dragon*: Every lesson is played against
   Rodving. The other dragons are locked here, each with the line "The lessons are
   played against Rodving." Continue goes straight to the setup table; there is no
   difficulty screen.
3. **The offer** (the Hand area) · *next* · `deck`: These five cards come from your
   Deck. Some difficulties let you raise a few cards before you set out; here you raise
   one to Level 3.
4. **card:DOE-A03** · *setup* `{picks: [A03]}` · `upgrade`: Choose Destruction. It is the only
   card on offer made to fight; at Level 3 its fire Attack rises to 10.
   Hint: "Choose Destruction: it is the one that fights."
5. **screen** · *sequence*: lesson complete.

## Lesson 2: A Victory (`victory`)

1. **deck** · *next* · `deck`: Your Deck holds every card you have. Each Encounter, your
   Hand is drawn from it.
2. **key** · *next* · `key_card`, `hardship`: The top card is the Key Card. Its strip
   names the Encounter you face, and sometimes a Hardship that makes it harder (none
   here).
3. **encounter** · *next* · `enemy_figures`: An enemy: HP, Initiative, Attack and Armor,
   and the XP it is worth.
4. **ether:DOE-A03** · *next* · `ether`, `enhanced`: Each card belongs to an Ether. When
   the Element's Ether matches the Spell's enhanced action, you get the enhanced value.
5. **card:DOE-A06+DOE-A03** · *arrange* `{0/spell: A03, 0/boost: A06}` · `roles`: The Spell is
   what you do, the Element lends its Ether and Initiative, and the Boost adds to it.
   Swap Destruction into the Spell's place.
6. **place:reserve** · *next* · `reserve`: The card left out is your Reserve. It stays
   for the next Encounter.
7. **chip:initiative** · *next* · `initiative`: Frostfire Wall's Initiative 5 beats the
   enemy's 4, so it cannot strike first.
8. **aim** · *next*: Put the Boost on Attack.
9. **primary** · *play* `{spell: A03, element: A14, boost: A06, boost_to: attack}` ·
   `outcomes`: 10 + 2, less 1 for its fire Armor, makes 11: the HP exactly. HP or more
   is a Victory. Hint: "Spell: Destruction. Element: Frostfire Wall. Boost: Fleet Footed,
   on Attack."
10. **screen** · *sequence*: the result is shown.
11. **card:DOE-A10** · *next* · `upgrade`, `unspent_xp`: Spend the 7 XP. Tap Rain of
    Blood, your Reserve, to raise it a Level: it stays in your Hand. XP left unspent is
    lost.
12. **primary** · *upgrade* `{picks: [A10]}` · `cleanup`: Confirm. The Upgrade is made,
    then Cleanup: your Action Set is discarded, and you draw back up to four. Hint:
    "Upgrade Rain of Blood, once, then confirm."
13. **deck** · *sequence*: the draw.
14. **deck** · *next*: Your Reserve stayed, and the Deck is smaller. Lesson complete.

## Lesson 3: A Narrow Victory on a Journey (`narrow`)

1. **encounter** · *next* · `journey`: A Journey. You cross it with Move against MP.
   There is no Initiative and no Early Damage, and failing costs time, not cards.
2. **chip:time** · *next* · `time_penalty`: The Time Penalty is 2.
3. **place:0/spell** · *next* · `enhanced`: This Hand is dealt already in place.
   River Swiftness moves 6 with water, and Brute Force brings water. (Lessons 3–6 are
   all dealt in place; only Lesson 2 asks for a swap.)
4. **primary** · *play* `{spell: A09, element: A01, boost: A13, boost_to: attack}` ·
   `outcomes`: 6 + 3 = 9 against 12. Half the MP or more is a Narrow Victory: you earn
   the XP but pay the time. Hint: as the arrangement.
5. **screen** · *sequence*: the result plays out.
6. **deck** · *next* · `deck_clock`: Two cards left the top of your Deck. The Deck
   is also your clock: every card lost brings the end of the Region closer.
7. **xp** · *upgrade* `{}` (any Upgrade, or none) · `cleanup`: Spend the XP if you like, then confirm. Lesson complete.

## Lesson 4: A Loss, and Soaking the damage (`loss`)

1. **encounter** · *next* · `outcomes`, `divert`: This enemy has 13 HP. Nothing in your
   Hand reaches half of it. When an Encounter cannot be won, you may [[divert|Divert]]
   it; here, take the Loss.
2. **primary** · *play* `{spell: A13, element: A06, boost: A01, boost_to: attack}`:
   Fleet Footed is faster than the enemy, so at least it does not strike first. Hint:
   "Spell: Adapt. Element: Fleet Footed. Boost: Brute Force."
3. **screen** · *sequence*: the enemy strikes back.
3b. **soak** · *next* · `soak`: 3 shadow damage. You Soak it by Downgrading cards
   in your Hand.
4. **hand** · *next* · `armor`: Each card Soaks its Armor: River Swiftness 2, Fleet
   Footed 3, Adapt 2, Brute Force 2. Armor of the damage's own Ether counts double; none
   of these is shadow.
5. **card:DOE-A06** · *soak* `{picks: [A06]}` · `downgrade`: Fleet Footed's Armor 3
   covers it alone. It goes down a Level. Hint: "Soak with Fleet Footed."
6. **screen** · *next* · `trash`: A Level 1 card that is Downgraded is Trashed, gone for
   good.
7. **primary** · *upgrade* `{}`: Confirm to end the Encounter. Lesson complete.

## Lesson 5: Fuse two cards (`fuse`)

1. **encounter** · *next*: 9 HP, Armor against water. Your best Action Set falls short.
2. **card:DOE-A02** + **card:DOE-A03** (the lit rect spans both) · *next* · `fuse`: Two
   cards of the same Ether can be Fused. The top card fills a Role and counts as any
   Ether you choose; the bottom fills none. You need a full Hand, and both are discarded
   at Cleanup.
3. **action:fuse** · *fuse_begin*: Press Fuse.
4. **picker** · *fuse_element* `{top: A02, bottom: A03, element: fire}`: Fuse Sword of
   Light on top of Destruction, as fire. Hint: "Fuse Sword of Light over Destruction,
   as fire."
5. **primary** · *play* `{spell: A05, element: A02, boost: A09, boost_to: attack, fuse: {top: A02, bottom: A03, element: fire}}`:
   Rain of Blood's fire Attack is now enhanced: 8 + 2 = 10. Hint: as the arrangement.
6. **screen** · *sequence*: the result is shown.
7. **primary** · *upgrade* `{}` · `cleanup`: Confirm. Both Fused cards are discarded at
   Cleanup; Fusing cost you a card you could have kept. Lesson complete.

## Lesson 6: The end of a Region (`region_end`)

1. **deck** · *next* · `region_end`: Two cards left in your Deck. A Region lasts while
   your Hand and Deck together can give a fresh Hand and a Key Card: five cards.
2. **primary** · *play* `{spell: A13, element: A10, boost: A01, boost_to: attack}`:
   5 + 3 = 8, the MP exactly.
3. **primary** · *upgrade* `{}`: Confirm. Cleanup leaves three cards. The Region is over.
4. **screen** · *sequence*: the Region ends.
4b. **deck** · *next* · `region_end`: Every card not Trashed is gathered, shuffled and
   dealt again in Region 2. Cards keep their Levels.
5. **screen** · *next*: After Region 4 comes the Final Battle against the dragon.
   Lesson complete. Then the summary (see [tutorial-flow.md](tutorial-flow.md)).
