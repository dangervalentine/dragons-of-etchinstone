# Data Model: In-Game Rulebook

The rulebook is static content compiled into the game (`ui/model/rulebook.gd`) plus one value that lives for the session. Nothing is saved to disk.

## Rulebook

The module itself. It holds the content and the helpers that turn it into what the overlay draws.

| Field | Type | Notes |
|---|---|---|
| `SECTIONS` | `const Array[Dictionary]` | Sections in reading order (FR-005) |
| `CREDIT` | `const String` | Attribution to the original designer and publisher (FR-021), shown on the first page |
| `NUMBERS` | `const Dictionary` | The whitelist for `{n:NAME}` tokens, mapping a name to an engine constant: `HAND_SIZE`, `FINAL_JOURNEY_HAND`, `MAX_DIVERTS`, `KNOCK_OUT_DISCARD` |
| `position` | `static var Dictionary` | Reading position (see below) |

**Helpers** (static, pure, tested headless):

- `section_count() -> int`
- `page_count(section: int) -> int`
- `page(section: int, page: int) -> Dictionary`: the page with tokens expanded, ready to draw: `{text: Array[Block], aside: Array[Block], terms: Array[String]}`
- `terms(section: int, page: int) -> Array[String]`: Glossary ids marked in that page's text column, first use first, no repeats (aside terms are explained by the aside)
- `terms_in(strings: Array) -> Array[String]`: the same, for any strings
- `find(section_id: String) -> int`: index of a section, or -1
- `step(pos: Dictionary, delta: int) -> Dictionary`: the next (+1) or previous (-1) page, crossing section boundaries. It returns `pos` unchanged at either end of the book
- `expand(text: String) -> String`: the tokens of R4 turned into BBCode (bold terms, `[img]` icons, engine numbers)
- `difficulty_rows() -> Array`: one row per `Game.DIFFICULTY` entry, for the generated table

## Section

| Field | Type | Rules |
|---|---|---|
| `id` | `String` | Unique, snake_case, stable (used by `find` and the optional `section` of the `rulebook` intent) |
| `title` | `String` | As shown in the header and the contents |
| `pages` | `Array[Page]` | At least one |

## Page

| Field | Type | Rules |
|---|---|---|
| `text` | `Array[Block]` | The text column: `p`, `steps`, `list`, `note` blocks. At most 130 words in total (R13) |
| `aside` | `Array[Block]` | Optional. A `figure` or `table` block. The terms chips are added below it automatically |

## Block

A dictionary with one kind key:

| Kind | Shape | Drawn as |
|---|---|---|
| `p` | `{"p": String}` | A paragraph (rich text, tokens expanded) |
| `steps` | `{"steps": Array[String]}` | A numbered list |
| `list` | `{"list": Array[String]}` | A bulleted list. An item may start with `[[id]]: ` to read as a labelled definition |
| `note` | `{"note": String}` | A tinted call-out for a tip or a digital-game aside ("The game does this for you.") |
| `table` | `{"table": {"head": Array[String], "rows": Array[Array[String]]}}` or `{"table": "difficulty"}` | A grid of labels. Cell text may use `{icon:id}`. `"difficulty"` is generated from `difficulty_rows()` |
| `figure` | `{"figure": "mage" \| "enemy" \| "journey" \| "dragon"}` | A labelled example from `rulebook_figure.gd` (R7) |

An aside holds one figure or one table. A section whose outline lists several gets them on separate pages.

**Validation** (enforced by `tests/test_rulebook.gd`, R11):

- Every `[[id]]` is a Glossary id. Every `{icon:id}` names a file in `art/icons/`. Every `{n:NAME}` is in `NUMBERS`.
- After expansion no `[[`, `{icon:` or `{n:` remains.
- No banned physical-handling or out-of-scope phrase appears (R11, item 4).
- Total words ≤ 3,500, and words per page text column ≤ 130.

## Reading position

| Field | Type | Rules |
|---|---|---|
| `section` | `int` | 0 ≤ section < `section_count()` |
| `page` | `int` | 0 ≤ page < `page_count(section)` |

**Lifecycle**: It starts at `{section: 0, page: 0}` when the game launches. Opening the rulebook with no `section` shows this position. Opening it with a `section` id moves to page 0 of that section. Every page change (Previous, Next, a contents choice, a key) writes it. Closing leaves it as it is. Relaunching resets it.

## Section outline

The planned reading order. Ids are fixed now; titles and how the text splits into pages are settled while writing, within the page budget. Topics in brackets are the SC-004 coverage each section answers for.

| # | id | Title | Covers | Aside |
|---|---|---|---|---|
| 1 | `welcome` | Welcome to Vale | Short story setup; goal: four Regions, then the Final Journey and Final Enemy; how you win and lose [goal, win/lose]; credit | — |
| 2 | `mage_cards` | Mage Cards | Levels 1–4; each figure; Key Card role [Mage cards] | figure: mage |
| 3 | `regions` | Regions and Encounters | Four Regions; enemies and Journeys; Encounter number from the Key Card; XP reward [Region cards] | figure: enemy |
| 4 | `dragons` | The Dragons | Initiative, Early Damage, Armor, MP and HP tiers [Dragon cards] | figure: dragon |
| 5 | `setup` | Starting a Game | What you choose (dragon, difficulty, alternate rules); the game builds the Deck and deals {n:HAND_SIZE} cards | — |
| 6 | `encounter` | An Encounter | The five phases at a glance; the cycle repeats until the Region ends | table: phases |
| 7 | `challenge` | Challenge Phase | Scout ahead; Hardships; Divert, up to {n:MAX_DIVERTS} times, and its cost [Challenge, Divert, Hardships] | table: Hardships |
| 8 | `action` | Action Phase | Spell, Element and Boost Roles; Reserve card; fewer than three cards; Fusing and its cost [Roles, Fusing] | — |
| 9 | `enemies` | Fighting an Enemy | Boost to Attack or Initiative; Initiative and Early Damage; Basic or Enhanced Attack; Armor; outcome [Enemy Abilities, outcomes] | table: Attack vs HP; Abilities (one aside per page) |
| 10 | `journeys` | Making a Journey | Basic or Enhanced Move; Boost; Reserve Boost on a matching Enhanced Move; outcome [Journey Perils, outcomes] | figure: journey; table: Move vs MP; Perils |
| 11 | `penalty` | Penalty Phase | Totals applied at once; Time Penalties; damage, Soaking, double Armor; Trash; Knock Out (discard {n:KNOCK_OUT_DISCARD}) [Time Penalties, damage, Soaking, Knock Out] | — |
| 12 | `upgrade_cleanup` | Upgrade and Cleanup | Spending XP, what can't be Upgraded, unspent XP lost; discard and draw back to {n:HAND_SIZE} [Upgrading] | — |
| 13 | `region_end` | End of a Region | Fewer than five cards left; the next Region; Trashed cards stay out [End of the Region] | — |
| 14 | `final_journey` | The Final Journey | {n:FINAL_JOURNEY_HAND} cards; two Action Sets; one Fuse; Regroup once; Total Move vs MP tiers [Final Journey, Regroup] | table: MP tiers |
| 15 | `final_enemy` | The Final Enemy | All remaining cards; two Action Sets; Total Initiative and Attack; Armor once per Ether; survive the damage [Final Enemy] | table: HP tiers |
| 16 | `scoring` | Scoring | Lose: 0; win: total Levels of untrashed cards after the final Soak [scoring] | — |
| 17 | `ethers` | The Four Ethers | Strengths of Water, Fire, Lightning, Shadow; Shadow's flexible actions [Ether elements] | — |
| 18 | `difficulty` | Difficulty and Alternate Rules | Six levels and what each changes; where they're chosen; Cavalier; Glass Cannon [difficulty, alternate rules] | table: difficulty (generated) |

Since 2026-10-18, The Four Ethers comes second, right after Welcome to Vale (owner request), so the Ethers are known before the cards that use them; the others keep their order.

The physical book's Ordering Your Hand, the DIZED tutorial, Variants and the Tracking Crystal are left out (FR-014, FR-019).
