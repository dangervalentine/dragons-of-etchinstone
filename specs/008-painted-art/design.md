# 008 Painted art: design

Replace the flat white silhouettes in `art/creatures/` with a consistent, coloured set:
the 16 enemies and 4 dragons as painted cut-outs, the 16 Journeys and the Final Journey
as full-frame paintings. Static art only; animation is feature 009 (below).

## Intent

What the user asked for:

- A coloured set, generated from the current art as inspiration, consistent across all
  37 images.
- The look of Slay the Spire: flat, a handful of colours, small amounts of very simple
  shading.
- Creatures as cut-outs; landscapes full-frame.
- Enemies will later stand on a region backdrop, but no backdrop in this pass.
- The Ether shown as a painted accent colour, not a runtime tint.
- Animation later, with Skeleton2D: pivots on the image, the parts cut and rigged, and
  procedural motion (breathing, lagging tails and spines, hit kicks, tweened attack
  poses), for the dragons and every enemy. This pass renders the assets.

Assumed, to confirm in review:

- Each creature keeps its current pose and outline, so the art stays recognisable and
  the dragons' existing joint points stay roughly in place for the rig.
- The etched-stone UI (feature 006) is unchanged around the new art.
- The old silhouettes stay in the repo as pose sources; nothing in the game loads them
  once this lands.

Success: all 37 images in the game, judged on the dark stone at 64 px and 300 px, read
as one set by one hand; each enemy's Ether is obvious at a glance; no Encounter shows
a white or tinted silhouette.

## Look

The style block replaces the woodcut block in `art/STYLE_PROMPT.md`. Its rules:

- Flat colour fills, 4 to 6 colours per image, one darker shade tone per colour at
  most, laid as a hard-edged shape, never a gradient or airbrush.
- A thin dark outline, one weight, on the outer edge and the main inner forms.
- Big simple shapes, readable as a thumbnail; little surface texture.
- **Shared base palette** for every creature: muted earth hides, dark umber, bone and
  horn, slate. Fixed hex values listed in the doc, named in the prompt.
- **Ether accent**: each enemy's element (its attack's element in `data/cards.json`) lives in its eyes,
  markings, weapon, breath or glow, in the game's own Ether colour (`T.ether`):
  fire, water, lightning, shadow. Only the accent carries it; the base palette is the
  same for all.
- Creatures: on a plain flat background for removal, whole body in frame, standing
  ones on the bottom margin. Head, tail and limbs drawn clearly separate from the body,
  not crossing in front of it, so feature 009 can cut them.
- Journeys: full-frame scene, no creatures or figures, same palette rules with the
  scene's Ether as its dominant light (lava glow, storm light, cold water).

## Generation (approach A)

`tools/paint_art.py` paints each creature over its old silhouette, styled by the
prompt and a shared set of references, through ComfyUI. Everything it sends is read
from `art/PAINTED_PROMPTS.txt`, which also records the lessons behind each rule.

1. **Base model**: FLUX.1-dev, Q4 on the Mac, Q8 on the Windows PC.
2. **Prompt**: the creature's SUBJECT (shapes, pose and materials; no colours), the
   EMANATION (one fixed sentence: the Ether's colour and texture coming from the eyes
   and one chosen place) and the shared STYLE (flat 2D game art, a shared muted palette
   with the Ether as the only bright colour, one light from the upper left with one
   hard shade tone, fixed framing, ferocious rather than cute).
3. **Start**: the creature's silhouette drawn flat mid-grey on light grey, at denoise
   0.88. Starting from noise gave soft, semi-3D images; the flat start keeps them flat.
   A silhouette can be replaced with a painted one in `art/source/painted/starts/`
   (the Wereboar's, with its tail out and its spear raised to throw).
4. **Shared references**: the same images steer every creature through FLUX Redux at
   0.05 each (`art/source/painted/anchors/`). Per-creature references made each
   creature drift toward its own earlier look; above 0.05, Redux copies the
   references' colours and designs.
5. **Candidates**: 4 seeds per creature; the user picks, or the prompt is revised and
   the creature run again.
6. **Style LoRA, later and only if needed**: once 15 to 25 creatures are approved, if
   the set drifts, train a small style LoRA on the approved images on the Windows PC
   and regenerate only the drifters. Not one trained on the old silhouettes (it would
   teach the woodcut look), and none from another living artist's work.
7. **Where it runs**: the Windows PC, from this branch (see Status).

History (2026-10-17, on the Mac, Q4): the prompt-only style test gave flat, on-model
creatures with no outlines and soft ground shadows; journeys came out painterly and
are set aside. Iterations 2 to 3 found the rules above. No image is approved yet.

Scope for now: **creatures only** (16 enemies, then the 4 dragons). Journeys wait for
their own round, likely with a flat-landscape LoRA.

## Status and handoff (2026-10-17)

Moved from the Mac to the Windows PC. On the PC:

1. Check out branch `008-painted-art`.
2. `powershell -ExecutionPolicy Bypass -File tools\setup_comfyui.ps1 -Q8`; accept the
   FLUX.1-Redux-dev licence on Hugging Face, `.venv\Scripts\hf.exe auth login`, and
   run the setup again to fetch Redux. Start ComfyUI.
3. `%USERPROFILE%\ComfyUI\.venv\Scripts\python.exe tools\paint_art.py paint all --q8`
   (images to `build\art\painted\`).

Next: review iteration 3 (the four creatures in `PAINTED_PROMPTS.txt`, from the
shared anchors), then write the other twelve enemies into the file and run them.

Sizes: creatures 1024 × 1024. Journeys 1344 × 768 (FLUX native, about 16:9), shown
cropped to cover the art panel.

## Post-processing

`tools/cutout_art.py` (new) turns an approved creature image into the game asset:

- Background removal with BiRefNet (ComfyUI node, or the `rembg` package in ComfyUI's
  Python), then a small alpha erode and feather so no background fringe shows on the
  dark stone.
- **Palette cleanup**, light: snap near-matches to the shared palette (base colours,
  their shade tones and the four Ether accents) without merging small areas, and
  never touching saturated accent pixels. Per-image quantizing to 8 colours was tried
  and rejected: it greyed out the Ether accents (the naga's violet wisps and eyes).
- Ground shadow removed with the background.
- **Outline in post**: an outer outline of fixed width and colour drawn round the
  cut-out's alpha, the same on every creature, since FLUX draws none.
- Trim and re-centre on a 1024 × 1024 transparent canvas, standing creatures on the
  bottom margin, as `tools/frame_art.py` does for the silhouettes.
- Writes `art/painted/<name>.png`.

Journeys: deferred (see Generation).

Approved raw outputs of both are kept in `art/source/painted/`.

## Game changes

- `UI.art(name)` loads `art/painted/<name>.png` when it exists, else the old SVG, so
  the set can land a few at a time. `art_rect` and `art_crop` follow, scaled from the
  texture's real size rather than 512.
- **Tint**: painted art draws with `tint` white in `creature_idle.gdshader`. The
  shader's `glow` term must not wash out colour; check it, and limit it to a slight
  brightening for painted art.
- **Idle motion**: kept, on the whole image. Breathe, hover, sway and so on work on any
  texture.
- **Dragons**: drawn whole, as one layer. `Art.layers()` returns the single image for a
  painted dragon, so the head and jaw no longer move apart until feature 009. Their
  `HEADS` crop rects are re-measured on the painted art for the selection cards and
  the face frame.
- **Enemy crop**: `encounter_face.gd`'s outline measurement works from alpha, so it
  carries over; its constants may need retuning for painted figures.
- **Journeys**: `encounter_face.gd` draws a Journey's art to cover the whole art slot
  (crop to fill, centred), inside the existing frame, instead of as a cropped figure.
  A Journey is known by `enc.kind`.
- **Backdrop slot**: the enemy art slot draws an optional backdrop texture beneath the
  figure, empty for now. `Art.backdrop(region)` returns `""` in this pass.
- `art/creatures/CREDITS.md` and the header of `ui/model/art.gd` describe the new set.

## Out of scope (feature 009 and later)

- Cutting creatures into parts, Skeleton2D rigs, pivots, procedural or keyed animation.
- Region backdrops.
- Redrawing the card icons, launcher icon or UI.

## Testing

- `tests/test_art.gd`: every name in `Art.ENEMIES`, `JOURNEYS`, `DRAGONS` and
  `FINAL_JOURNEY` has an `art/painted/` PNG (once the full set lands; during the
  rollout, a PNG or the SVG); creature PNGs have transparent corners; Journey PNGs are
  opaque; every painted dragon has a `HEADS` rect inside its image.
- Visual check on the emulators and web build (`install-on-emulators`): one Encounter
  and one Journey from each region, the dragon selection screen and the ending screen,
  each at phone and desktop size.

## Licensing

FLUX.1-dev's licence is non-commercial for the weights, and its outputs may be used
for any purpose, commercial included. The chosen LoRA's licence must allow the same;
check it before choosing, and record it in `CREDITS.md`.
