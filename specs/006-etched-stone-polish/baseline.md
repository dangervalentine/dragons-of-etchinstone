# Baseline: play-screen space before feature 006

Recorded 2026-10-15 on commit `b7335d9`. Run with `godot --path . -s tools/space_audit.gd`.
The raw numbers are in `baseline.json`.

A zone is the panel drawn on screen. For the Hand it is the panel round the cards.
The header and the action bar draw no panel, so they are not measured. `phone-small`
(1334 × 750) gives the same 1280 × 720 design view as `phone-16x9`, so its rows are
identical.

| State (1280 × 720) | Role band (w × h) | Band share of content | Emptiest zone |
|---|---|---|---|
| Challenge, nothing placed | 824 × 153 | 14.7% | preview 17% |
| Challenge, one placed | 824 × 153 | 14.7% | preview 20% |
| Challenge, all placed | 824 × 153 | 14.7% | preview 26% |
| Soak | 824 × 153 (recap) | 14.7% | **preview 42%** |
| Upgrade | 824 × 153 (recap) | 14.7% | **preview 71%** |
| Next Encounter | 824 × 153 | 14.7% | preview 17% |
| Final Journey (two sets) | 824 × 96 | 9.2% | hand 22% |

Zones over a third empty today, which US1 must fix: the preview at Soak and at
Upgrade.

SC-001 target: a one-set role display of at most 0.5 × 824 × 153 = 63,036 square
units.
