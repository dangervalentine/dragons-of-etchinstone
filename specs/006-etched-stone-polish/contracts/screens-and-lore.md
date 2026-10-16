# Contract: Screens and Lore Framing (US5)

This applies only after the owner approves the restyled play screen (US3 scenario 4,
FR-027). Each screen keeps every control and value it has today (FR-024). The framing
goes around the content and is drawn with the raised boxes, flat ground and woodcut
ornaments of contracts/boxes-and-ground.md. There is no rift light: the "Rift source"
column of revision 1 is gone.

| Screen | File | Frame | Must keep |
|---|---|---|---|
| Title / dragon choice | `ui/screens/title_screen.gd` | **The Tear**: the game title cut into a lintel; the four dragon tiles as plinths; an `orn_rift` tear drawn flat behind them | Dragon tiles with all stats, Settings, Glossary, How to Play, Continue, credits text |
| Rules setup | `ui/screens/rules_screen.gd` | **The elders' proclamation**: a slab headed by `orn_tower` and "By order of the Tower"; options as lines with `orn_divider`; `orn_seal` on Continue | Difficulty, every alternate rule, Back, Continue |
| Play | `ui/screens/play_screen.gd` | The board (contracts role-slots, math-box, boxes-and-ground, board-life) | Everything |
| Final Battle | (play screen) | The board; the road from 003 in the Encounter frame | Both Action Sets, tiers, Reserve, Soak |
| Region banner | `ui/overlays/stage_banner.gd` | A **lintel** across the screen | Region number, name and glyph |
| Ending | `ui/screens/ending_screen.gd` | An **inscribed slab**; the verdict cut into it | Verdict, summary, Play again, To title |
| Rulebook | `ui/overlays/rulebook_overlay.gd` | **Scroll**: a slab with `orn_scroll_end` caps | Contents, sections, figures, tables, navigation |
| Glossary | `ui/overlays/glossary_popover.gd` | Scroll (full); a small slab (popover) | Every entry |
| Inspect | `ui/overlays/inspect_overlay.gd` | Slab | Every Level face |
| Menu, confirm, size notice | `menu_overlay.gd`, `confirm_dialog.gd`, `size_notice.gd` | Slab | Every option and button |

## Guarantees

- No screen loses a control, value or text it shows today (FR-024). `tools/ui_check.gd`
  still finds every control it presses.
- Every screen meets the size, tap and contrast floors (FR-021).
- Nothing glows or moves on any ground (FR-016).
- Before/after screenshots of each row exist for the owner's side-by-side (SC-005;
  quickstart §6).
