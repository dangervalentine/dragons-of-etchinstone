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

For **journey scenes**, add this sentence to the style block:

> The scene is a self-contained vignette emblem with its edges shaped into the
> silhouette, not a full-bleed landscape. It feels ominous and ancient.

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

Sixteen of the images are built from two layers, like a cut-out puppet:

- **the body**, which holds still apart from the idle motion every creature already has
- **one moving part**, such as a lower jaw, a wing, a tail or a pair of eyes, which moves
  on its own over the body

Both layers are always shown together as one creature. Both are tinted the same flat
colour, so wherever the part overlaps the body the join is invisible. That's what makes
this work with silhouettes: there's no edge to hide, as long as the body is solid behind
the joint.

Each part moves in one of these ways:

| Motion | What it does | Used for |
|---|---|---|
| hinge | rotates back and forth around the pivot by the given angle | jaws, wings, tails, a club arm |
| slide | moves out and back along a direction by the given distance | a tortoise head from its shell |
| blink | squashes flat about its own centre, briefly, at random intervals | eyes in the dark |
| flicker | appears in short bursts, then disappears | a lightning bolt |
| surge | grows upward from the pivot and settles back | a lava geyser |

### Making the two layers

1. **Generate the whole image** from its subject line, the style block and the
   moving-part sentence. Draw it in its rest pose (jaw closed, wing raised, eyes open),
   which is also how it appears with reduced motion on. Get this image approved before
   splitting it.
2. **Paint a mask over the moving part**: white over the part, black everywhere else, the
   same size as the image. Extend it a little past the joint, into the body, so the part
   has some overlap to pivot on. Any image editor will do.
3. **Make the body layer by inpainting** the whole image inside that mask, with this
   prompt (filling in the gap from the table):

   > Remove the [MOVING PART] completely. In its place, continue the body as solid
   > black: [WHAT FILLS THE GAP]. Keep everything outside the masked area exactly as it
   > is. It is still a single solid black silhouette on pure white.

   This step matters. When the jaw opens or the wing lowers, whatever was behind it
   shows, and that must be solid body, not a hole. For the dragons, inpainting kept
   redrawing a second jaw instead of removing it, so their bodies are drawn by
   `tools/draw_throat.py <name>` instead.
4. **Convert the layers.** Keep the whole image as well: it's still used for small
   icons and the title screen, and it means nothing breaks before the game supports
   parts.

   ```sh
   python3 tools/vectorize_art.py tortoise.png art/creatures/tortoise.svg
   python3 tools/vectorize_art.py tortoise-body.png art/creatures/tortoise-base.svg
   python3 tools/vectorize_art.py tortoise.png --mask tortoise-mask.png art/creatures/tortoise-part.svg
   ```

5. **Note the pivot.** Read the joint's position in 512-unit coordinates off the
   converted image (top-left is 0, 0) and write it in the table below. That's the point
   the part turns about, or slides and grows from.

Every layer is the same 512 × 512 canvas, so the layers line up exactly with no offsets
to track. `ui/fx/creature.gd` draws the part texture in the same shader pass as the
body (`creature_idle.gdshader`'s `has_part`/`part_tex`), so the tint's alpha is applied
once and they breathe, hover and move as one creature.

## Subject lines

Ether is the Encounter's element from `data/cards.json`. Names come from
`ui/model/art.gd`. Every subject line is followed by the style block (plus the journey
sentence for journeys, and the moving-part sentence where there's a part).

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
| peaks | High Peaks · lightning *(journey)* | Three jagged jade mountain peaks like broken fangs, a storm cloud snagged on the tallest, and a forked lightning bolt splitting the sky down to one peak. | Lightning bolt · flicker, pivot at the cloud · the sky is empty behind it, so nothing to fill: the body layer is the image without the bolt. |
| waterfall | The Falls · water *(journey)* | A waterfall pouring from the open jaws of a giant dragon face carved into a cliff, with mist billowing at its foot. | — |
| mountain-road | Mountain Road · fire *(journey)* | A switchback road climbing a steep mountain past burning beacon braziers, with a skull-carved waystone at the bend. | — |
| cave-entrance | Dark Cave · shadow *(journey)* | A cave mouth shaped like a monster's open maw with stalactite fangs, and two eye cut-outs glinting in the darkness inside. | Eyes · blink, pivot between the eyes · the darkness inside the cave, solid. Here the part is the solid area around the eyes, with the eye holes cut in it, so a blink squashes the holes shut. |

### Journey scenes, Region 2: Living Marshes

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| swamp | Sunken Mire · fire *(journey)* | A sunken mire of dead, twisted trees and bubbling pools, with will-o'-wisp flames hovering above the water and a half-sunk skull. | — |
| river | Black River · water *(journey)* | A black river winding between dead reeds, the ridged back of a serpent breaking the surface beside a ruined bridge pillar. | — |
| willow-tree | Weeping Willows · lightning *(journey)* | A weeping willow with a gnarled, mournful face in its trunk, drooping branches hanging like long hair, and a lightning-scorched split down its centre. | — |
| cliff-crossing | Cliff Path · shadow *(journey)* | A narrow ledge path across a sheer cliff above an abyss, with giant faces carved into the rock and stones crumbling away into the dark. | — |

### Journey scenes, Region 3: Burning Basin

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| volcano | Ash Slopes · water *(journey)* | A steep volcano under a fall of ash, a boiling crater lake at its summit sending up columns of steam, and scree of skulls on its slopes. | — |
| desert | Glass Desert · lightning *(journey)* | A desert of fused glass dunes with lightning-struck spires of fulgurite and the bleached ribcage of a giant beast half buried in the sand. | — |
| lava | Lava Fields · fire *(journey)* | Fields of cracked lava crust with molten rivers as cut-out channels and a tall fiery geyser bursting from a vent at the centre. | Geyser · surge 30% taller, pivot at the vent · the vent's rim and the crust, solid; the sky behind is empty. |
| underground-cave | Deep Caverns · shadow *(journey)* | A deep cavern of stalactites and stalagmites arranged like a ribcage, clusters of glowing crystals, and a narrow path vanishing into darkness. | — |

### Journey scenes, Region 4: Forest of Gath

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| rope-bridge | Rope Bridge · water *(journey)* | A sagging rope bridge over a misty gorge, with frayed ropes, missing planks and a torrent rushing below. | — |
| forest-entrance | Forest Gate · shadow *(journey)* | The edge of a dark forest where two ancient trees arch together into a gate with clawed branches, and several pairs of eyes peer out of the darkness between them. | Eyes · blink, pivot at the centre of the eyes · the darkness between the trees, solid. As with the Dark Cave, the part is the solid area around the eyes, with the eye holes cut in it. |
| burning-forest | Burning Wood · fire *(journey)* | A forest ablaze: charred trunks wrapped in rising tongues of flame and sparks drifting upward. | — |
| stone-path | Old Stone Stair · lightning *(journey)* | An old stone stair climbing steeply between toppled statues, its steps carved with runes, up to a lightning-struck archway at the top. | — |

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
| monkey-brawler | Frenzied Ape · fire | A wiry, long-armed ape brawler seen side-on facing right, leaping forward with both fists raised high over its head, its mouth open in a fanged shriek. A sleeveless robe hangs from one shoulder, tied with a long sash whose ends stream behind it as two smooth ribbons. Its fur is one sleek solid mass with a clean outline, and a long thin tail curls up behind it. | — |
| crane-monk | Crane Monk · water | A tall crane warrior monk seen side-on facing right, striding forward on two long thin legs with its feet on the bottom margin, holding a long straight sword angled forward and down. Its body is wrapped in a long robe of smooth cloth tied with a sash, the hem one clean curved edge sweeping back behind it. Its back is one smooth, unbroken curve of plain cloth from shoulder to hem. A long S-curved neck lifts its slender head at the upper right, with a long, straight spear-like beak and a narrow, slanted, hollow white eye with no pupil under a heavy brow. | — |
| lion-archer | Lionel Archer · shadow | A broad-shouldered lion warrior seen side-on facing right, drawing a tall longbow with an arrow nocked and aimed forward, its arm pulled back to its cheek. Its mane is one heavy solid mass swept back from the face with a smooth scalloped edge, and a short beard juts from its jaw. It wears a sleeveless tunic belted at the waist and a quiver of arrows on its back. | — |

#### Region 2: Living Marshes

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| axe-gnome | Rapid Gnome · shadow | A small hunched, menacing gnome seen side-on facing right, leaping forward with a short hand-axe gripped out in front of it. It wears a very tall pointed hat that curls back and ends in a small round bell. It has a huge hooked nose, a narrow, slanted, hollow white eye with no pupil under a heavy scowling brow, and its hair and long beard are one smooth solid wedge of black sweeping back behind its head, with a single clean, unbroken edge. Its short legs are bent mid-leap, its pointed boots just above the bottom margin. | — |
| club-ogre | Bog Ogre · lightning | A hulking pot-bellied ogre seen side-on facing right, a huge club made from a tree branch with a stone lashed to its end resting over one shoulder. Long drooping moss hangs from its jaw as one smooth solid beard, its brow is heavy, and its arms are thick and long, ending in big fists. It wears a simple loincloth, and its back is broad and rounded. | — |
| horned-goblin | Goblin Raider · fire | A lean goblin raider seen side-on facing right, charging forward in a crouch with a long curved blade raised behind it. It wears a round helmet with two great curving horns, and armour plates on its shoulders and forearms with smooth edges. Its long pointed ears sweep back and its grin is full of sharp teeth. | — |
| marsh-treant | Swamp Treant · water | A tall, stooped tree creature seen side-on facing right, striding forward on two thick root-like legs, its long arms hanging low and ending in a few gnarled branch fingers. Its body is a twisted trunk of smooth bark with a few deep grooves running down it, its head a knot of wood with a hollow eye and a gaping mouth hole. A few bare branches rise from its shoulders as smooth, tapering forks. | — |

#### Region 3: Burning Basin

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| naga | Naga Goro · shadow | A serpent-bodied naga seen side-on facing right, its long snake body coiled on the ground and rising into a lean upper torso with four long arms, each ending in a clawed hand reaching forward. Its snake head has a hood swept back behind it and a forked tongue flicking out. A row of broad, rounded plates runs down the back of its body. | — |
| twin-ogre | Twin Ogre · water | A massive two-headed ogre seen side-on facing right, both heads side by side on thick necks with heavy jaws and tusks. It holds a huge spiked club raised over its shoulder in one fist. Its body is a broad barrel shape with a heavy belly, wearing a wide leather belt and a loincloth, and it stands on two short, thick legs. | — |
| twin-ghoul | Conjoined Ghoul · fire | A shambling two-headed ghoul seen side-on facing right, its two hunched heads joined at the shoulders, lurching forward with its long arms hanging low and its hands clawed. Its body is gaunt and stooped, wrapped at the waist in a long ragged cloth that falls as one smooth shape. A deep scar runs down its chest as a single white cut. | — |
| boar-shaman | Wereboar · lightning | A stocky boar-headed warrior shaman seen side-on facing right, charging forward with a long spear held low in both hands, the spearhead a flame shape. Two curved tusks jut up from its snout and its ears sweep back. It wears heavy shoulder armour and a belted tunic, and a short cape hangs behind it in one smooth piece. | — |

#### Region 4: Forest of Gath

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| hedge-wizard | Hedge Wizard · shadow | A hunched old wizard seen side-on facing right, leaning forward on a tall crooked staff whose top curls into a hook. He wears a wide-brimmed pointed hat with a drooping tip and a long coat. His hair and beard flow back from under the brim as one smooth solid mass. One hand reaches forward with long fingers spread, as if casting. | — |
| goblin-hexer | Goblin Hexer · fire | A goblin witch-doctor seen side-on facing right, hurling a spell forward from one outstretched hand, a bolt of energy leaving its fingers as a single curling white cut-out. It wears a long hooded robe that sweeps back behind it in one smooth shape, a necklace of large curved tusks on its chest, and it grips a short bone staff in the other hand. Long pointed ears jut out from under the hood. | — |
| antler-horror | Antlered Horror · lightning | A gaunt, long-limbed horror seen side-on facing right, loping forward on all fours like a hunting beast. Its head is a bare stag's skull with a long open jaw full of teeth and a hollow eye socket. Two great branching antlers rise from the skull. A heavy shaggy mantle covers its shoulders as one smooth solid hump, and its thin limbs end in long claws. | — |
| gath-brute | Brute of Gath · water | A colossal hunchbacked brute seen side-on facing right, so wide it fills the frame, its tiny head low at the front of an enormous rounded back and shoulders. Three or four large curved horns rise from its back in a row. Its thick arms hang to the ground, ending in heavy fists. Thick stitched scars cross its hide as a few white cut lines. | — |

### The Final Journey

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| horizon-road | The Final Journey *(journey)* | A long road running to the horizon between leaning standing stones, with a dragon perched at its far end, its wings folded. | — |

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

The current images are from game-icons.net under CC BY 3.0, except the four dragons
(see CREDITS.md, "Made for this project"). When you replace an image,
update its row in `art/creatures/CREDITS.md`: name the generator, and if the result was
made from the original icon (for example by image-to-image), keep the icon's credit
too. `tests/test_art.gd` checks that every image has a row there.
