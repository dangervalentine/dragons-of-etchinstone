# MageCard

The frame every Mage Card shares; the Ether field is the only thing that changes colour.

- Frame and title band `card-frame`, corners `radius-card` (cards are paper, so they are the one rounded thing on screen). Stat ribbon `card-ribbon` with cost left and XP right in `brass-bright`.
- Field: the Ether's mineral pigment, `ether-lapis`, `ether-ochre`, `ether-amethyst` or `ether-cinnabar`, under the existing topographic texture at low contrast.
- Figures sit on `stat-plate`, never on the field. The highlighted figure (the value this card is contributing) fills with the Ether's `-bright` token; on ochre it takes `on-brass` text.
- Selected: 3px `brass` ring + `shadow-lift`. Out of play: full greyscale at `opacity-out-of-play`.
- Ethers are told apart by the glyph in the title band first and hue second. Lapis, amethyst and cinnabar sit close in lightness, so the glyph is not optional.
- `card-name` is 11pt minimum. At today's sizes a name like MOTIVATED FLIGHT wraps to two lines at about 7pt; give the title band the full card width and drop the inline glyph circle before shrinking type.
