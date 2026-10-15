# Contract: Screens and Lore Framing (US4)

This applies only after the owner approves the play-screen style frame (FR-023).
Each screen keeps every control and value it has today (FR-020). The framing goes
around the content.

| Screen | File | Frame | Rift source | Must keep |
|---|---|---|---|---|
| Title / dragon choice | `ui/screens/title_screen.gd` | **The Tear**: the game title carved into a lintel; the four dragon tiles as plinths before a tall rift seam | The seam behind the tiles, tinted by the selected dragon's Ether | Dragon tiles with all stats, Settings, Glossary, How to Play, Continue, credits text |
| Rules setup | `ui/screens/rules_screen.gd` | **The elders' proclamation**: a slab headed by `orn_tower` and "By order of the Tower"; options as carved lines; `orn_seal` on Continue | Neutral, from above the slab | Difficulty, every alternate rule, Back, Continue |
| Play | `ui/screens/play_screen.gd` | **The board**: stone, wells and a rail (contracts stone-and-rift, role-rail, board-life) | Encounter frame | Everything |
| Final Battle | (play screen) | The board, with the dragon's Ether lighting the rift and the road from 003 carved into the Encounter well | Dragon frame | Both Action Sets, tiers, Reserve, Soak |
| Region banner | `ui/overlays/stage_banner.gd` | A carved **lintel** across the screen; the rift tint changes beneath it to the next Region's first Encounter | The lintel's underside | Region number, name and glyph |
| Ending | `ui/screens/ending_screen.gd` | An **inscribed slab**. Victory: the verdict carved, seams gold. Loss: seams dim and cracked | Behind the slab | Verdict, summary, Play again, To title |
| Rulebook | `ui/overlays/rulebook_overlay.gd` | **Scroll**: a slab body with `orn_scroll_end` caps | Neutral | Contents, sections, figures, tables, navigation |
| Glossary | `ui/overlays/glossary_popover.gd` | Scroll (full); a small slab (popover) | Neutral | Every entry |
| Inspect | `ui/overlays/inspect_overlay.gd` | Slab | The card's Ether | Every Level face |
| Menu, confirm, size notice | `menu_overlay.gd`, `confirm_dialog.gd`, `size_notice.gd` | Slab | Neutral | Every option and button |

## Guarantees

- No screen loses a control, value or text it shows today (FR-020). `tools/ui_check.gd`
  still finds every control it presses.
- Every screen meets the size, tap and contrast floors (FR-017).
- Every screen has rift light and seam shimmer. The ambient motion pauses under an
  overlay, and the overlay's own slab carries its light.
- Before/after screenshots of each row exist for the owner's side-by-side (SC-003;
  quickstart §5).
