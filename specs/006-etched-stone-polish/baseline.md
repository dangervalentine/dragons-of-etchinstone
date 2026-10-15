# Baseline: play-screen space before feature 006

Recorded 2026-10-15 on commit `b7335d9`. Run with `godot --path . -s tools/space_audit.gd`.
The raw numbers are in `baseline.json`.

A zone is the panel drawn on screen. For the Hand it is the panel round the cards.
The header and the action bar draw no panel, so they are not measured. `phone-small`
(1334 × 750) gives the same 1280 × 720 design view as `phone-16x9`, so its rows are
identical.

Empty is measured as the share of a zone's height, in 16-unit rows, that nothing
drawn crosses (research D12). The baseline was re-recorded with that measure on the
pre-change code (`02004c7`).

| State (1280 × 720) | Role band (w × h) | Band share of content | Emptiest zone |
|---|---|---|---|
| Challenge, nothing placed | 824 × 153 | 14.7% | preview 31% |
| Challenge, one placed | 824 × 153 | 14.7% | preview 31% |
| Challenge, all placed | 824 × 153 | 14.7% | none 0% |
| Soak | 824 × 153 (recap) | 14.7% | preview 25% |
| Upgrade | 824 × 153 (recap) | 14.7% | preview 25% |
| Next Encounter | 824 × 153 | 14.7% | preview 31% |
| Final Journey (two sets) | 824 × 96 | 9.2% | **preview 38%** |

Zone over a third empty today, which US1 must fix: the Final Journey preview.

SC-001 target: a one-set role display of at most 0.5 × 824 × 153 = 63,036 square
units.
