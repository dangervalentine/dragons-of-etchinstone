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
> in the picture. Detail inside the shape is shown only by a few broad white cut-outs,
> each as thick as a finger at icon size, such as wide cracks between plates, eye
> holes, gaps between teeth, ribs and feather notches; most of the shape is unbroken
> black. A strong, simple outline that reads instantly at thumbnail size. Square
> composition, side or three-quarter profile, the whole subject centred and filling
> most of the frame, with an even white margin and every part inside the frame. A
> creature that stands has its feet resting on the bottom margin, ending in a clean
> edge. The creature is mythic and menacing rather than natural: exaggerated
> proportions, jagged spines, horns, hooked claws, unnatural growths, eyes shown as
> empty cut-outs. It belongs to an ancient, dragon-haunted realm.

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
   shows, and that must be solid body, not a hole.
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
to track. Playing the parts still needs game work: `ui/fx/creature.gd` has to draw the
part over the base with the same idle shader settings, so they breathe and hover as one
creature, and add the part's own motion on top.

## Subject lines

Ether is the Encounter's element from `data/cards.json`. Names come from
`ui/model/art.gd`. Every subject line is followed by the style block (plus the journey
sentence for journeys, and the moving-part sentence where there's a part).

### Dragons

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| spiked-dragon-head | Grimroch, Scales of Stone · water | The head of an immense dragon seen side-on, its hide plated like weathered granite slabs with water running down channels between them, a crown of jagged rock spikes, deep-set eye cut-outs, and closed jaws lined with tusk-like fangs. | Lower jaw · hinge 18° open, pivot at the back of the jaw · the underside of the skull and throat, solid. |
| dragon-head | Helsang, The Undying · shadow | The head and neck of an undead dragon seen side-on, half scaled flesh and half bare skull, tattered frills and sunken eye sockets, with wisps of shadow curling out through the gaps between its bones, jaws closed. | Lower jaw · hinge 25° open, pivot at the back of the jaw · the throat and neck, solid. |
| sea-serpent | Rodving, The Last Breath · fire | A great serpent dragon rising in coils from a sea of fire, seen side-on, with a finned crest made of flame, gills shown as cut-out slits, smoke trailing from its closed mouth. | Lower jaw · hinge 22° open, pivot at the back of the jaw · the throat, solid. |
| wyvern | Vuurhast, Death and Darkness · lightning | A two-legged wyvern seen side-on with its near wing raised high, lightning running through the wing membrane as cut-out veins, a barbed tail and a horned, skull-like head; the far wing is folded against its body. | Near wing · hinge 35° downstroke, pivot at the shoulder · the shoulder and back, solid. |

### Region 1: Jade Mountains

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| harpy | Crag Harpy · lightning | A crag harpy seen side-on: a hag-faced creature with a feathered torso, wild storm-blown hair, its near wing raised high and tattered, eagle talons for legs, and sparks of lightning crackling from its claws; the far wing is folded behind. | Near wing · hinge 35° downstroke, pivot at the shoulder · the shoulder and back, solid. |
| salamander | Ember Salamander · fire | A long salamander seen side-on, its skin cracked into glowing ember plates, a crest of flickering flame along its spine, a tail curling into a flame tip, and its mouth closed. | Lower jaw · hinge 20° open, pivot at the back of the jaw · the throat, solid. |
| ice-golem | Ice Golem · water | A hulking golem built from jagged ice shards and frozen boulders, with a cavernous chest around a cut-out frost-rune core, a beard of icicles and fists like blocks of glacier. | — |
| troll | Mountain Troll · shadow | A hunched mountain troll seen side-on with moss and stone grown into its hide, a tusked underbite, deep-set eyes, and its near arm hanging with a club of rock. | Near arm and club · hinge 25° upward, pivot at the shoulder · the shoulder and flank, solid. |
| peaks | High Peaks · lightning *(journey)* | Three jagged jade mountain peaks like broken fangs, a storm cloud snagged on the tallest, and a forked lightning bolt splitting the sky down to one peak. | Lightning bolt · flicker, pivot at the cloud · the sky is empty behind it, so nothing to fill: the body layer is the image without the bolt. |
| waterfall | The Falls · water *(journey)* | A waterfall pouring from the open jaws of a giant dragon face carved into a cliff, with mist billowing at its foot. | — |
| mountain-road | Mountain Road · fire *(journey)* | A switchback road climbing a steep mountain past burning beacon braziers, with a skull-carved waystone at the bend. | — |
| cave-entrance | Dark Cave · shadow *(journey)* | A cave mouth shaped like a monster's open maw with stalactite fangs, and two eye cut-outs glinting in the darkness inside. | Eyes · blink, pivot between the eyes · the darkness inside the cave, solid. Here the part is the solid area around the eyes, with the eye holes cut in it, so a blink squashes the holes shut. |

### Region 2: Living Marshes

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| lizardman | Marsh Lizardman · shadow | A marsh lizardman warrior with a frilled crest and armour of bone and reed, drawing a longbow with a shadow-fletched arrow. | — |
| eel | Thunder Eel · lightning | A long thunder eel in an S-curve, with a ridged fin along its back, a gaping mouth of needle teeth and lightning running down its body as cut-out veins. | — |
| toad-teeth | Bog Toad · fire | A bloated bog toad the size of a cart, seen side-on, its warty back studded with smouldering vents and its wide closed mouth lined with jagged teeth. | Lower jaw · hinge 25° open, pivot at the corner of the mouth · the throat and the inside of the mouth, solid. |
| spectre | Marsh Spectre · water | A drowned spectre in a hooded shroud of tattered mist, frost-rimed skeletal hands reaching forward, a hollow face with two eye cut-outs, its body trailing away into nothing. | — |
| swamp | Sunken Mire · fire *(journey)* | A sunken mire of dead, twisted trees and bubbling pools, with will-o'-wisp flames hovering above the water and a half-sunk skull. | — |
| river | Black River · water *(journey)* | A black river winding between dead reeds, the ridged back of a serpent breaking the surface beside a ruined bridge pillar. | — |
| willow-tree | Weeping Willows · lightning *(journey)* | A weeping willow with a gnarled, mournful face in its trunk, drooping branches hanging like long hair, and a lightning-scorched split down its centre. | — |
| cliff-crossing | Cliff Path · shadow *(journey)* | A narrow ledge path across a sheer cliff above an abyss, with giant faces carved into the rock and stones crumbling away into the dark. | — |

### Region 3: Burning Basin

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| rock-golem | Obsidian Golem · shadow | A golem of jagged, glassy obsidian slabs with fracture lines as cut-outs, a hollow skull face with a dark core, and shoulders crowned with shards. | — |
| tortoise | Steam Tortoise · water | A colossal ancient tortoise seen side-on, whose shell is a small volcano: a cracked rocky cone with a crater at its peak, from which three thick plumes of steam billow upward. Jagged basalt spines run along the shell's rim, its legs are pillars of cooled lava, and a beaked, fanged, skull-like head pushes out on a long neck. | Head and neck · slide 40 units back into the shell, pivot at the shell opening · the front of the shell, solid, with a dark opening where the neck emerges. |
| scorpion | Sand Scorpion · fire | A giant sand scorpion seen side-on, with armour plates like burnt bronze, pincers raised, and its tail arched high overhead with a dripping venom stinger. | Tail · hinge 20° forward strike, pivot at the base of the tail · the rear of the body, solid. |
| vulture | Storm Vulture · lightning | A gaunt storm vulture seen side-on with its near wing raised high and tattered, its feather tips splitting into forked lightning, a bare hooked skull-like head with a crest of crackling plumes, ribs showing through its starved body, and talons trailing lightning bolts; the far wing is folded behind. | Near wing · hinge 35° downstroke, pivot at the shoulder · the shoulder and back, solid. |
| volcano | Ash Slopes · water *(journey)* | A steep volcano under a fall of ash, a boiling crater lake at its summit sending up columns of steam, and scree of skulls on its slopes. | — |
| desert | Glass Desert · lightning *(journey)* | A desert of fused glass dunes with lightning-struck spires of fulgurite and the bleached ribcage of a giant beast half buried in the sand. | — |
| lava | Lava Fields · fire *(journey)* | Fields of cracked lava crust with molten rivers as cut-out channels and a tall fiery geyser bursting from a vent at the centre. | Geyser · surge 30% taller, pivot at the vent · the vent's rim and the crust, solid; the sky behind is empty. |
| underground-cave | Deep Caverns · shadow *(journey)* | A deep cavern of stalactites and stalagmites arranged like a ribcage, clusters of glowing crystals, and a narrow path vanishing into darkness. | — |

### Region 4: Forest of Gath

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| angular-spider | Shadow Spider · shadow | A giant spider hanging from a single thread, with too many eyes, armoured jointed legs like black blades, a skull pattern cut into its abdomen and dripping fangs. | — |
| goblin-head | Goblin Archer · fire | The head and shoulders of a hooded goblin archer with long notched ears, a jagged grin and warpaint, drawing a flaming arrow back to its cheek. | — |
| wolf-head | Thunder Wolf · lightning | The head of a dire wolf seen side-on, with a frost-rimed mane bristling into lightning bolts, cut-out eyes, and closed jaws baring their fangs. | Lower jaw · hinge 22° open, pivot at the back of the jaw · the throat and the mane beneath it, solid. |
| evil-tree | Rotwood Treant · water | A rotting treant with a gaping hollow mouth, branches for clawed arms, roots like tentacles, and fungus and moss dripping from its limbs. | — |
| rope-bridge | Rope Bridge · water *(journey)* | A sagging rope bridge over a misty gorge, with frayed ropes, missing planks and a torrent rushing below. | — |
| forest-entrance | Forest Gate · shadow *(journey)* | The edge of a dark forest where two ancient trees arch together into a gate with clawed branches, and several pairs of eyes peer out of the darkness between them. | Eyes · blink, pivot at the centre of the eyes · the darkness between the trees, solid. As with the Dark Cave, the part is the solid area around the eyes, with the eye holes cut in it. |
| burning-forest | Burning Wood · fire *(journey)* | A forest ablaze: charred trunks wrapped in rising tongues of flame and sparks drifting upward. | — |
| stone-path | Old Stone Stair · lightning *(journey)* | An old stone stair climbing steeply between toppled statues, its steps carved with runes, up to a lightning-struck archway at the top. | — |

### The Final Journey

| File | Name · Ether | Subject | Moving part · motion · fill behind it |
|---|---|---|---|
| horizon-road | The Final Journey *(journey)* | A long road running to the horizon between leaning standing stones, with a dragon perched at its far end, its wings folded. | — |

## Converting an image

```sh
pip install pillow numpy potracer
python3 tools/vectorize_art.py generated/troll.png art/creatures/troll.svg
```

Add `--mask mask.png` to keep only the part of the image under the mask's white area.

## Credits

The current images are from game-icons.net under CC BY 3.0. When you replace an image,
update its row in `art/creatures/CREDITS.md`: name the generator, and if the result was
made from the original icon (for example by image-to-image), keep the icon's credit
too. `tests/test_art.gd` checks that every image has a row there.
