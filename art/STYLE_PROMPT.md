# Creature and landscape art: generation prompts

These prompts are for regenerating the 37 silhouettes in `art/creatures/`: 32 Encounters,
4 dragons and the Final Journey. The goal is one consistent style, with every animal
pushed into something fantastical and threatening.

## What the game needs from an image

The game draws each image as a single flat colour. It tints the silhouette with the
Encounter's Ether colour at runtime and moves it with `ui/fx/shaders/creature_idle.gdshader`.
That means every output must be:

- one solid shape with no shading, no gradients and no second colour
- detail carved out as negative space (holes in the shape), never drawn in a second tone
- readable as a small icon of 64 px and as a large one of 300 px or more
- square, with the subject centred and nothing cropped
- standing on the bottom margin if it stands on the ground (the "breathe" motion
  scales from a point 95% of the way down the image)

Generate the images black on white. `tools/vectorize_art.py` turns them into the white,
transparent 512 × 512 SVGs the game loads.

## Style block

Paste this after every subject line, unchanged.

> A bold game-icon silhouette in the style of a heraldic woodcut: one solid shape of
> pure flat black, isolated on a plain pure-white background. The subject stands alone
> in empty white space, with clean white all around it and beneath it, and nothing else
> in the picture. The shape is carved with three to six bold white gashes, each a wide,
> sharp-edged gap like a stroke cut into a linocut block, which mark the creature's
> main features. The eye is a narrow, naturally shaped white cut-out, almond-shaped or
> slanted and set under a heavy brow, never a round circle, and hollow: an empty slit
> of pure white with no pupil inside it, which gives an eerie, menacing stare. The
> outline is smooth and confident, built from a few large sweeping curves: limbs, wings and shells have
> clean, unbroken edges, with only one or two sharp features where they matter, such
> as a hooked beak or claws. Restraint everywhere: large plain areas of solid black,
> and no small spikes, frills or feather fringes added along the edges. A strong,
> simple outline that reads instantly at thumbnail size. Square composition, side or
> three-quarter profile, the whole subject centred and filling most of the frame, with
> an even white margin and every part inside the frame. A creature that stands has its
> feet resting on the bottom margin, ending in a clean edge. The creature is mythic and
> menacing rather than natural, through exaggerated proportions and one or two
> unnatural features rather than added ornament. It belongs to an ancient,
> dragon-haunted realm.

For **journey scenes**, use this style block in place of the one above. The creature
block talks about eyes, feet and menace, and FLUX answers it by putting a monster into
every landscape, so scenes have their own:

> A bold game-icon silhouette of a natural landscape in the style of a heraldic
> woodcut: one solid shape of pure flat black, isolated on a plain pure-white
> background, as a self-contained vignette emblem rather than a full-bleed picture.
> The scene is one landmark built from a few large, simple shapes, resting on a short
> ground line that ends cleanly at both sides, with clean white all around and above
> it. The shapes are carved with a few bold white gashes, like strokes cut into a
> linocut block, that mark ridges, water and paths. The outline is smooth and
> confident, built from a few large sweeping curves and straight edges. Trees have a
> few thick, smooth, tapering branches, never a mass of twigs, and there are no small
> spikes, grass tufts, leaves or fringes along any edge. Large plain areas of solid
> black. It is a landscape only: there are no animals, creatures, people, faces, eyes
> or figures anywhere in it. Square composition, the scene centred and filling most
> of the frame, with an even white margin and every part inside the frame. It reads
> instantly at thumbnail size and feels wild, ancient and ominous.

For **images with a moving part** (see below), add this sentence, naming the part:

> The [MOVING PART] is one clear, distinct piece that meets the rest of the body at a
> single joint, and doesn't cross in front of other detail.

## Negative prompt

FLUX.1-dev, which `tools/generate_art.py` uses, ignores negative prompts. Every rule is
written into the style block as what the image *is*. For example, it says "clean white
all around it and beneath it" instead of "no ground shadow". Write any new rule the same
way. For models that do take a negative prompt:

> photorealistic, painterly, colour, grey, gradient, soft shading, airbrush, outline
> stroke, background scenery, ground, ground shadow, splatter, horizon line, text,
> letters, watermark, signature, border, frame, multiple subjects, cute, cartoon,
> chibi, thin hairline detail, cropped limbs, cluttered

## Keeping the set consistent

- Use the same model, aspect ratio, sampler and settings for every image. Change only
  the subject line.
- Once the first image is approved, use it as the style reference for all the others,
  if your tool supports style references.
- Fix the seed where you can, and note the seed of each image you approve in the table
  below.
- Judge every result tinted in its Ether colour on the dark game background, not as
  black on white. Weak cut-outs only show once it's tinted.

## Moving parts

The dragons are the only silhouettes with parts that move on their own: the head, which
lifts, and the jaw, which opens with it. Everything else about them bends in place by
soft bones, as the rest of the silhouettes breathe, hover and sway. Every part is the
same 512 × 512 canvas, so they line up exactly, and `ui/fx/creature.gd` draws them all
in one shader pass (`creature_idle.gdshader`), so the tint's alpha is applied once and
they move as one creature.

### Dragons drawn in Illustrator

Each dragon has one source file, `art/creatures/<name>-parts.svg`, a 512 × 512 artboard
drawn in black, exported from Illustrator. Everything else is generated from it.

- **`head`**: the one part cut out. It turns on its own, so extend its neck end a little
  under the body.
- **`jaw`**: a sublayer inside `head`, cut at the hinge, its back end extended up under
  the head. It opens with the head and never gets a line cut between them.
- **Every other layer** (the body, and arms, tail or wings if you keep them on layers
  of their own) is drawn into the body, in stacking order. These bend in place by soft
  bones rather than coming apart, so there's no need to cut them or draw hidden ends.
- **Gaps**: each layer is separated from what's below it by a thin gap. Draw a white
  offset path to set it by hand, or leave it out and one is made, 2 units wide.
- **Points**: circles named `head-joint` and `jaw-joint` mark what the head and jaw
  turn about. Other circles named `<anything>-joint` or `<anything>-tip` can place soft
  bones (`Art.BONES` in `ui/model/art.gd` refers to them by name). Circles are only
  read, never drawn. Names use hyphens; Illustrator's `_1_` suffixes are dropped.

Then run:

```sh
python3 tools/split_rig.py art/creatures/<name>-parts.svg <name>
```

That writes the body, head and jaw layers (`<name>-rig-*.svg`), `<name>-rig.json`
(pivots, drawing order and points), the head alone for the dragon selection cards
(`<name>-rig-head-whole.svg`) and the whole silhouette `<name>.svg`. It won't replace a
`<name>.svg` it didn't make, so an export saved there by mistake is never lost.
`--head-only` writes just the head for the cards, for a dragon whose motion is all soft
bones. How the head and jaw move is set in `Art.RIGS`, and the bones in `Art.BONES`.

## Subject lines

Ether is the Encounter's element from `data/cards.json`. Names come from
`ui/model/art.gd`. Every subject line is followed by the style block (the scene block for journeys), and
the moving-part sentence where there's a part.

Writing a subject line:

- **Put the unnatural feature in the silhouette.** The style block holds detail back,
  so anything that is only detail gets dropped. The volcano shell worked because it
  changes the tortoise's outline. The vulture's ribs, skull and lightning wingtips
  didn't, and it came out a plain eagle. So the vulture's wing is a storm cloud and
  its tail is a bolt of lightning: both are part of its shape.
- **Name the eye here.** Say "a narrow, slanted eye" in the subject line. FLUX gives
  the start of the prompt the most weight, and the same instruction left only in the
  style block still came out as a round dot.
- **Keep it to a few features.** Three or four parts, each described once. Every
  extra detail named is more texture added to the image.

### Dragons, full body

One image per dragon, shown whole where the player chooses a dragon and cropped to
the head where they face it. All four share one pose so the head crops line up:
side-on facing right, standing on the hind legs, the head held high at the upper
right, clear of the wings and body. Drawn from the dragon cards' artwork.

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| grimroch | Grimroch, Scales of Stone · water | A hulking ice dragon seen side-on facing right, standing hunched on two thick hind legs like a great ape, with a massive barrel torso, long powerful arms hanging almost to the ground and ending in huge clawed hands, and no wings. Its hide is armoured in overlapping plates of glacier ice, and its back is a row of long, straight icicles standing up like spires: each one a narrow, perfectly straight cone of ice tapering to a needle point, tallest over the shoulders and shorter down the neck, stopping where the tail begins. Its tail is thick, heavy and completely smooth, with no spikes or spines, tapering to a blunt point along the ground. Its broad reptile head is thrust forward at the upper right, with a heavy brow and closed jaws lined with tusk-like fangs of ice. | Lower jaw · hinge 18° open, pivot at the back of the jaw · the underside of the skull and throat, solid. |
| helsang | Helsang, The Undying · shadow | An undead dragon seen side-on facing right, standing upright on two gaunt hind legs, its emaciated body all sinew with its ribs cut out as gaps, long thin clawed arms and a long thin tail. Tattered bat wings are folded half-open behind its back, with holes torn through them. On a long thin neck its narrow, skull-like head is held high at the upper right, crowned with branching antler-like horns, its jaws closed, with wisps of shadow curling out from between its ribs. | Lower jaw · hinge 25° open, pivot at the back of the jaw · the throat and neck, solid. |
| rodving | Rodving, The Last Breath · fire | A lean, fierce fire dragon seen side-on facing right, standing upright on two hind legs, with huge bat wings spread wide and raised behind it and flames licking along their edges. A long S-curved neck lifts its horned, wedge-shaped head high at the upper right, its jaws closed with a curl of smoke from the nostrils, and a very long whip-like tail barbed with spines curls along the bottom of the frame. | Lower jaw · hinge 22° open, pivot at the back of the jaw · the throat, solid. |
| vuurhast | Vuurhast, Death and Darkness · lightning | A long serpentine eastern lightning dragon seen side-on facing right, rearing upright on two short clawed hind legs, its long snake-like body ribbed with belly plates and coiled in loops beneath it, and no wings. Its back, neck and tail are smooth and covered only in fine scales, with no spines, fins or spikes anywhere along them, and lightning runs along its body as cut-out veins. Its long head rises on a curving neck at the upper right, with two horns shaped exactly like jagged zigzag lightning bolts standing up from its skull, long whiskers trailing from its snout, and closed jaws. | Lower jaw · hinge 22° open, pivot at the back of the jaw · the throat, solid. |

### Journey scenes, Region 1: Jade Mountains

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| peaks | High Peaks · lightning *(journey)* | Tall, narrow karst pillars of rock rising steeply from a bank of mist, sheer-sided and flat-topped, a single twisted pine leaning from the top of the tallest, and a forked lightning bolt striking down to it from the sky. | Lightning bolt · flicker, pivot at the cloud · the sky is empty behind it, so nothing to fill: the body layer is the image without the bolt. |
| waterfall | The Falls · water *(journey)* | A tall waterfall pouring in one smooth sheet from a gap between two steep karst pillars into a pool, its mist rising at the foot as a few large, smooth, rounded billows. | — |
| mountain-road | Mountain Road · fire *(journey)* | A steep karst mountain with a switchback road zigzagging up its face as a white cut through the black rock, and a twisted pine leaning out from the bend at the top. | — |
| cave-entrance | Dark Cave · shadow *(journey)* | A sheer cliff with a tall, dark cave mouth at its foot, the opening a rough arch edged by a white gash, a few heavy stalactites hanging from its lip, and a twisted pine growing on the cliff above. | — |
### Journey scenes, Region 2: Living Marshes

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| swamp | Sunken Mire · fire *(journey)* | A sunken mire: two or three twisted swamp trees standing on tall arching stilt roots in still black water, their crowns a few thick bare branches, the water's surface marked by a few long white ripple lines. | — |
| river | Black River · water *(journey)* | A broad river winding toward the viewer as a white ribbon cut through low black banks of twisted mangrove roots, a gnarled tree leaning over the water. | — |
| willow-tree | Weeping Willows · lightning *(journey)* | A great weeping willow on the bank of still water, its thick twisted trunk splitting into heavy limbs, its branches hanging in a few long smooth curtains down to the water. | — |
| cliff-crossing | Cliff Path · shadow *(journey)* | A sheer cliff face above a deep gorge with a narrow ledge path running across it as a white cut along the black rock, and one gnarled tree clinging to the edge. | — |

### Journey scenes, Region 3: Burning Basin

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| volcano | Ash Slopes · water *(journey)* | A steep volcano with a broad, broken crater, a column of smoke rising from it as a few large smooth rounded billows, and its slopes scored with long white gullies. | — |
| desert | Glass Desert · lightning *(journey)* | A desert canyon of tall rock spires and flat-topped mesas rising over smooth rolling dunes, with one bare dead tree in the foreground. | — |
| lava | Lava Fields · fire *(journey)* | Fields of cracked lava crust with molten rivers running through it as white cut-out channels, and a tall geyser of fire bursting from a vent at the centre. | Geyser · surge 30% taller, pivot at the vent · the vent's rim and the crust, solid; the sky behind is empty. |
| underground-cave | Deep Caverns · shadow *(journey)* | A deep cavern seen from inside: a great arch of rock with heavy stalactites hanging from its roof and stalagmites rising from its floor, and a narrow path winding away into the dark. | — |

### Journey scenes, Region 4: Forest of Gath

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| rope-bridge | Rope Bridge · water *(journey)* | A sagging rope bridge slung across a deep forest gorge between two great gnarled trees, its planks a row of short white cuts, and a river far below. | — |
| forest-entrance | Forest Gate · shadow *(journey)* | The edge of a dark forest where two huge gnarled trees lean together and their thick branches meet overhead in an arch, with a bright opening of white light between their trunks. | — |
| burning-forest | Burning Wood · fire *(journey)* | A burning wood: three charred tree trunks with a few thick bare branches, and tall, smooth tongues of flame rising between them. | — |
| stone-path | Old Stone Stair · lightning *(journey)* | An old stone stair climbing steeply between gnarled roots and boulders up to a ruined stone archway at the top. | — |

### Card-inspired Encounters

Each takes the idea of an enemy from the official cards, not its design. Every line
keeps to the house rules: side-on facing right, big smooth shapes (hair, fur, beards and
cloth as one solid mass with a clean edge), no texture words such as tattered, jagged,
warty or bristling, and at most one or two large sharp features. The panda, crane and
gnome lines are the ones their approved images were made from.

#### Region 1: Jade Mountains

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| panda-fighter | Shaolin Panda · lightning | A fierce red panda kung fu master seen strictly side-on facing right, its head in profile with the snout pointing right, crouched low like a predator in a wide fighting stance with both feet planted on the bottom margin. Its long wolfish muzzle is pulled back in a snarl, baring long fangs, its ears are laid flat back against the skull, and a heavy brow juts over a narrow, slanted, hollow white eye with no pupil. It wears a loose wrap-front jacket tied at the waist with a sash and wide trousers, the cloth in a few smooth sweeping folds. One clawed paw is thrust forward at the right and the other is drawn back beside its chest. Its fur is sleek, every edge a smooth clean curve, and behind it a long, thick tail curves up as one solid, smooth, tapering shape with a clean outline. | — |
| monkey-brawler | Frenzied Ape · fire | An angry silverback gorilla seen strictly side-on in profile facing right, a wild animal with no clothing, belt or sash. It stands hunched on its short legs and the knuckles of its huge long arms, its massive shoulders and back rising in a high rounded hump, its heavy domed head thrust forward with the jaw open in a roar showing long fangs, under a jutting brow ridge and a plain white slit of an eye with no pupil. It has no tail. Its body is one smooth, solid shape like bare skin, with no tufts or shaggy fur. Every edge is a smooth clean curve. | — |
| crane-monk | Crane Monk · water | A tall crane warrior monk seen side-on facing right, striding forward on two long thin legs with its feet on the bottom margin, holding a long straight sword angled forward and down. Its body is wrapped in a long robe of smooth cloth tied with a sash, the hem one clean curved edge sweeping back behind it. Its back is one smooth, unbroken curve of plain cloth from shoulder to hem. A long S-curved neck lifts its slender head at the upper right, with a long, straight spear-like beak and a narrow, slanted, hollow white eye with no pupil under a heavy brow. | — |
| lion-archer | Lionel Archer · shadow | A broad-shouldered lion warrior seen side-on facing right, drawing a tall longbow with an arrow nocked and aimed forward, its arm pulled back to its cheek. Its mane is one heavy solid mass swept back from the face with a smooth scalloped edge, and a short beard juts from its jaw. It wears a sleeveless tunic belted at the waist and a quiver of arrows on its back. | — |

#### Region 2: Living Marshes

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| axe-gnome | Rapid Gnome · shadow | A small hunched, menacing gnome seen side-on facing right, leaping forward with a short hand-axe gripped out in front of it. It wears a very tall pointed hat that curls back and ends in a small round bell. It has a huge hooked nose, a narrow, slanted, hollow white eye with no pupil under a heavy scowling brow, and its hair and long beard are one smooth solid wedge of black sweeping back behind its head, with a single clean, unbroken edge. Its short legs are bent mid-leap, its pointed boots just above the bottom margin. | — |
| club-ogre | Bog Ogre · lightning | A hulking pot-bellied ogre seen side-on facing right, a huge club made from a tree branch with a stone lashed to its end resting over one shoulder. Long drooping moss hangs from its jaw as one smooth solid beard, its brow is heavy, and its arms are thick and long, ending in big fists. It wears a simple loincloth, and its back is broad and rounded. | — |
| horned-goblin | Goblin Raider · fire | A lean, menacing goblin raider seen strictly side-on facing right, charging forward in a low crouch, a long curved blade with a plain grip and a round pommel held low in one hand. It wears a round helmet with two great smooth curving horns, and plain rounded armour plates on its shoulders and forearms. Its long pointed ears sweep back, its grin is full of sharp teeth, and its eye is a narrow, slanted, hollow white slit with no pupil. It has no hair; its skin is smooth and bare, with no fringes or tatters. Every edge is a smooth clean curve. | — |
| marsh-treant | Swamp Treant · water | A tall, menacing tree creature seen strictly side-on facing right, striding forward on two thick legs of root. Its body is one twisted trunk of smooth bark with a few long grooves, its long heavy arms are thick branches that hang low and end in three blunt, gnarled wooden fingers, and its head is a knot of wood with a gaping mouth hole and a narrow, slanted, hollow white eye with no pupil. Two or three thick bare branches rise from its shoulders and fork once into smooth, blunt, tapering ends. It has no leaves, moss, twigs or spikes. Every edge is a smooth clean curve. | — |

#### Region 3: Burning Basin

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| naga | Naga Goro · shadow | A menacing snake-headed man seen strictly side-on facing right, looming forward over its prey with its shoulders hunched, in a long plain robe that falls to his feet as one smooth solid shape with a clean hem. Its clawed hands reach out of wide sleeves toward the right, the long hooked claws spread to strike. On a long, arched neck its smooth snake head is lowered and thrust forward in profile with no hood, the jaws gaping wide to show two long dripping fangs and a forked tongue, under a heavy brow and a narrow, slanted, hollow white eye with no pupil. A thick snake tail trails out from under the back of the robe. Every edge is a smooth clean curve, with no frills, ridges or tatters. | — |
| twin-ogre | Twin Ogre · water | A massive hairless ogre with two heads, seen strictly side-on facing right, striding forward. Two bald heads grow side by side from its broad hunched shoulders, one slightly higher and behind the other, both grim and brutish in profile: a low heavy brow, a scowling mouth with a thick underbite and two short tusks, and a plain white slit of an eye with no pupil. In one fist it grips a large, thick, gnarled wooden branch held upright as a club, as tall as the ogre, twisting slightly and knotted, with a stub of a broken branch near the top. Its arms are bare. Its body is a broad barrel shape with long thick arms, a wide belt and a plain loincloth with a clean, smooth hem, standing on two short, thick legs. Its skin is smooth and bare. Every edge is a smooth clean curve. | — |
| twin-ghoul | Conjoined Ghoul · fire | A gaunt, hairless ghoul with two heads, seen strictly side-on facing right, stooped and lurching forward. Two bald, smooth skull-like heads grow side by side from its broad hunched shoulders, one slightly higher and behind the other, both in profile facing right with long jaws, bared teeth and narrow, slanted, hollow white eyes with no pupils. Its long thin arms hang low in front of it, ending in hands with long claws. Its skin is smooth and bare, with no hair, fur or tatters. A plain cloth is wrapped at its waist and falls to the knee as one smooth solid shape with a clean hem. Every edge is a smooth clean curve. | — |
| boar-shaman | Wereboar · lightning | A stocky, hairless boar-headed warrior seen strictly side-on facing right, charging forward with a long spear held low in both hands, the spearhead a smooth leaf-shaped blade. Its head is a smooth wild-pig head in profile with a long blunt snout, two thick curved tusks jutting up, small ears laid flat back, and a heavy brow over a narrow, slanted, hollow white eye with no pupil. Its hide is smooth and bare, with no mane, bristles or tufts. It wears a rounded shoulder plate and a belted tunic, and a short cape hangs behind it in one smooth solid piece. Every edge is a smooth clean curve. | — |

#### Region 4: Forest of Gath

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| hedge-wizard | Hedge Wizard · shadow | A hunched old wizard seen side-on facing right, leaning forward on a tall crooked staff whose top curls into a hook. He wears a wide-brimmed pointed hat with a drooping tip and a long coat. His hair and beard flow back from under the brim as one smooth solid mass. One hand reaches forward with long fingers spread, as if casting. | — |
| goblin-hexer | Goblin Hexer · fire | A hunched, menacing goblin witch-doctor seen strictly side-on facing right, reaching forward with one clawed hand. It wears a long robe with a pointed hood pulled up over its head, the hood's opening framing a long hooked nose, a grin of sharp teeth and a plain white slit of an eye with no pupil. The robe is smooth and solid, falling to the ground in one simple shape with a clean, unbroken hem, a necklace of big pointed teeth, cut out in white, hangs on its chest, and it grips a tall plain staff in the other hand. Its feet are plain humanoid feet. It has no tail. Every edge is a smooth clean curve, with no fur, tatters or fringes. | — |
| antler-horror | Antlered Horror · lightning | A gaunt, menacing horror seen strictly side-on facing right, a hunched beast stalking forward on four long, thin, jointed legs ending in small hooves. Its body is one heavy, smooth, rounded hump with a clean outline, sloping down to a long neck. Its head is a bare stag's skull thrust low and forward, its long jaw open and full of sharp teeth, with a hollow white eye socket and no pupil. Two great antlers rise from the skull, each a few smooth, curving tines. Every edge is a smooth clean curve, with no fur tufts or fringes. | — |
| gath-brute | Brute of Gath · water | A colossal hunchbacked brute seen strictly side-on facing right, so wide it fills the frame: an enormous rounded back and shoulders towering over a small head set low at the front, with a fanged jaw and a narrow, slanted, hollow white eye with no pupil. Several large, smooth, curved horns sweep forward and up around its head and shoulders. Its massive arms hang low, ending in heavy clawed fists, it stands on short thick legs, and a short thick tail curves out behind. Its hide is smooth and bare. Every edge is a smooth clean curve, with no fur or fringes. | — |

### The Final Journey

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| horizon-road | The Final Journey *(journey)* | A long straight road running from the viewer to the horizon between two rows of leaning standing stones, toward a far jagged mountain. | — |

## Generating

`tools/generate_art.py` sends these prompts to a ComfyUI running FLUX, which
`tools/setup_comfyui.sh` (macOS, Linux) or `tools/setup_comfyui.ps1` (Windows) sets
up. Run the art tools with ComfyUI's own Python, which the setup script gives
everything they need: `~/ComfyUI/.venv/bin/python` on a Mac,
`$HOME\ComfyUI\.venv\Scripts\python.exe` on Windows. Images land in `build/art/`.

- `restyle <names>` redraws the current silhouette in this style, keeping its pose and
  outline. This is the main way to make the set. `--denoise` (0.9 by default) sets how
  far it may stray: lower keeps more of the original, higher follows the prompt more.
  0.7 came back almost unchanged; give several values (`--denoise 0.85 0.9 0.95`) to
  compare them in one run.
- `start <names>` writes the starting image to `build/art/starts/`. Paint new
  features onto it in solid black (a lightning tail, a raised wing) or paint parts
  out in white, and `restyle` uses the painted version from then on.
- `generate <names>` draws from the prompt alone, with no starting image.
- `--count 4` tries four seeds, and `--seed` sets the first. An image that already
  exists is skipped, so a stopped batch picks up where it left off.
- `--q8` uses the sharper Q8 models, on a computer with the memory for them.

### On the Windows PC

With the repo cloned and `setup_comfyui.ps1 -Q8` run once:

1. Start ComfyUI and leave it running in its own window:
   `cd $HOME\ComfyUI; .venv\Scripts\python.exe main.py`
2. In a second window, from the repo:
   `$HOME\ComfyUI\.venv\Scripts\python.exe tools\generate_art.py restyle panda-fighter crane-monk --denoise 0.85 0.9 0.95 --count 2 --q8`
3. Review and pick in `build\art\`, then commit the chosen SVGs (below). The PNGs
   stay out of git, so copy any worth keeping to the other computer by hand.

If the setup script was run before restyle existed, run it again: it only adds what's
missing.

## Converting an image

```sh
python3 tools/vectorize_art.py build/art/panda-fighter-restyle50-7300.png art/creatures/panda-fighter.svg
```

Add `--mask mask.png` to keep only the part of the image under the mask's white area.
A thin ground line under the subject is removed; `--keep-ground` keeps it.

## Credits

Every image was made for this project (see CREDITS.md); the journeys are first drafts. When you replace an image,
update its row in `art/creatures/CREDITS.md`: name the generator, and if the result was
made from the original icon (for example by image-to-image), keep the icon's credit
too. `tests/test_art.gd` checks that every image has a row there.
