# Feature Specification: Locked Aspect Ratio and Display Mode

**Feature Branch**: `008-resolution-settings`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "create a resolution setting and lock the aspect ratio of the playing area so users can't mess with the intended layout of the game. we would want a full windowed screen, and then a handful of size options for desktops screens, 1080p 2550 4k 720p. if you can prevent window size adjustment, even better. mobile wouldn't need this."

## Clarifications

### Session 2026-10-17

- Direction from the user: the goal is to keep the aspect ratio, not a particular size. The game should open in a window at a set starting size, and maximising it to fill the screen must be allowed.
- Q: Should the settings still list 720p, 1080p, 1440p and 4K, or should the game simply open at one sensible window size that the player can then resize or maximise? → A: No size list. The game opens in a window sized to fit the monitor, and the settings only offer a Windowed / Full screen toggle (plus F11 or Alt+Enter).
- Q: When the player drags the window to an odd shape, should the window snap back to 16:9, or can it be any shape while the game inside stays 16:9 with borders? → A: The window can be any shape. The play area stays 16:9 and centred, with dark borders filling the leftover space.

### Amendment 2026-10-17: phones and tablets

- Direction from the user: phones aren't exactly 16:9, and the bars waste their screens. Keep the 16:9 lock on desktop and web, but let the mobile apps adapt within the range of common phone and tablet shapes ("clamp-like"). Upright screens stay disallowed.
- Q: Where does the mobile clamp sit, and do tablets adapt too? → A: Phones grow wider and tablets grow taller, up to the existing maximum design size of 1760×990 units. That covers phones up to about 22:9 and tablets down to 4:3. Past the maximum the layout stops growing, stays centred, and the stone backdrop fills the rest.
- The web build stays locked even in a phone's browser.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - On desktop and web, the layout always keeps its intended shape (Priority: P1)

A player on a desktop or in a browser, at any window size, sees the game exactly as it was laid out: the board, cards, dragon and text keep their designed 16:9 proportions. If the window or screen is a different shape, the play area stays 16:9 and the spare space at the sides or top and bottom is filled with a plain dark border that matches the game's look. The game never stretches, squashes or rearranges its screens to fill an odd shape.

**Why this priority**: This is the main point of the feature. Players can resize and maximise the window, so the aspect lock is what keeps the layout intact.

**Independent Test**: Run the game at several window and screen shapes (16:9, 16:10, 21:9, 4:3, a tall phone-like shape, and a window dragged to an odd size). On every screen (title, dragon select, play, rules, records, ending), the play area stays 16:9, nothing is distorted, and nothing is clipped.

**Acceptance Scenarios**:

1. **Given** a 16:10 monitor with the game maximised or full screen, **When** the play screen is shown, **Then** the play area is 16:9 and thin borders fill the top and bottom.
2. **Given** a 21:9 ultrawide monitor, **When** any screen is shown, **Then** the play area is 16:9 and centred, with borders on the left and right.
3. **Given** a 16:9 monitor in full screen, **When** any screen is shown, **Then** the play area fills the whole screen with no borders.
4. **Given** the player drags a window edge to make the window much wider or taller, **When** the window changes shape, **Then** the play area rescales right away and stays 16:9.
5. **Given** any of the above, **When** the player hovers, clicks or drags a card, **Then** the pointer hits what is drawn under it (input lines up with the scaled play area).

---

### User Story 2 - Opens in a well-sized window and can go full screen (Priority: P2)

On desktop, the game opens in a normal window that is 16:9 and sized to fit the monitor comfortably. The player can resize the window, maximise it, or switch to full screen with the Windowed / Full screen toggle in the settings, F11, or Alt+Enter. The game remembers whether it was windowed or full screen the next time it starts.

**Why this priority**: This is the desktop behaviour the user asked for. It depends on Story 1 so that every window size looks right.

**Independent Test**: On a desktop build, launch the game and check the window's starting size and shape. Maximise it, resize it, switch it with the settings toggle, F11 and Alt+Enter, then quit and relaunch.

**Acceptance Scenarios**:

1. **Given** a 1920×1080 monitor and a first launch, **When** the game starts, **Then** it opens as a 16:9 window that fits on the monitor with its title bar visible, centred on the screen.
2. **Given** the game is windowed, **When** the player presses the maximise button, **Then** the window fills the screen (apart from the taskbar) and the play area grows while staying 16:9.
3. **Given** the game is windowed, **When** the player turns on Full screen in the settings, or presses F11 or Alt+Enter, **Then** the game covers the entire monitor without a title bar or window frame.
4. **Given** the game is full screen, **When** the player presses F11 or Alt+Enter, or turns Full screen off in the settings, **Then** the game goes back to a window.
5. **Given** the player quit while in full screen, **When** they start the game again, **Then** it opens in full screen.

---

### User Story 3 - Phones and tablets fill their screens (Priority: P2)

On the Android and iOS apps, the game fills the screen with no black bars. The layout keeps the same arrangement as on desktop: the same regions, in the same order, at the same sizes or larger. A wider phone gives the layout more width, a 4:3 or 16:10 tablet gives it more height, and the notch and home indicator stay clear of every control. On a screen beyond the range the layout is built for, the layout stops growing and stays centred, with the stone backdrop around it.

**Why this priority**: Every common phone is longer than 16:9, so under the lock a phone loses about a sixth of its width to black bars. It depends on Story 1 only in sharing the same layout.

**Independent Test**: Run the layout at the mobile test shapes (16:9 phone, 19.5:9 notched phone held both ways, 4:3 tablet) and check every screen fills the screen, keeps its arrangement, and keeps every control inside the safe area.

**Acceptance Scenarios**:

1. **Given** a 19.5:9 notched phone in landscape, **When** any screen is shown, **Then** the game fills the screen with no bars, and nothing the player presses or reads is under the notch or the home indicator.
2. **Given** the same phone turned end over end, **When** the notch moves to the other side, **Then** the layout moves to keep clear of it.
3. **Given** a 4:3 tablet, **When** the play screen is shown, **Then** the layout is taller than on desktop and fills the screen, with no bars.
4. **Given** a 16:9 phone, **When** any screen is shown, **Then** it looks exactly as it does on a 16:9 desktop.
5. **Given** a screen wider than about 22:9, **When** any screen is shown, **Then** the layout stays at its widest size, centred, with the stone backdrop on both sides and no black bars.

---

### Edge Cases

- **Monitor smaller than the smallest starting window (below 1280×720)**: the starting window is the largest 16:9 size that fits the monitor's usable area, even if it's smaller than 1280×720.
- **Very small window**: if the player drags the window very small, the play area shrinks with it and stays 16:9. The window can't be made smaller than a minimum size at which the game is still readable.
- **Multiple monitors**: the starting window and full screen use the monitor the game window is on.
- **Missing or corrupt settings file**: the game opens in the default starting window and doesn't crash.
- **Display mode changed in the middle of a game**: the game state isn't lost, and the current screen redraws at the new size.
- **Web build in a desktop browser**: the Windowed / Full screen toggle and starting window size don't apply because the browser controls the page size. The 16:9 aspect lock with borders still applies.
- **Upright or tiny window**: only the web build shows the "Turn your device sideways / Widen the window" notice, because a browser can't always be locked to landscape. The app is locked to landscape, and a desktop window still shows the whole game letterboxed, so neither shows it.
- **Mobile (Android/iOS)**: no display setting is shown. The game fills the screen within the clamp (Story 3, FR-012) in both landscape orientations; the app can't be held upright.
- **Web build in a phone's browser**: it's a web build, so the 16:9 lock with bars applies, and the size notice shows if the phone is held upright.
- **OS display scaling (e.g. 150% on Windows)**: the starting window still fits on screen with its title bar visible.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On desktop and web builds, the play area MUST always be shown at a 16:9 aspect ratio on every screen and window size, scaled evenly to the largest size that fits the window or screen.
- **FR-002**: Any space left around the play area MUST be filled with a plain border in a dark colour that matches the game's art. Game content MUST NOT be drawn into that space.
- **FR-003**: Pointer and touch input MUST line up with the scaled play area, so a click or tap lands on the element drawn under it.
- **FR-004**: On desktop builds, the settings MUST offer a Windowed / Full screen toggle. F11 and Alt+Enter MUST switch between the two modes from any screen.
- **FR-005**: Full screen MUST make the game a borderless window covering the whole monitor it's on, with no title bar or frame.
- **FR-006**: When windowed, the game MUST open in a 16:9 window centred on the current monitor. The window MUST be the largest of 1280×720, 1920×1080, 2560×1440 and 3840×2160 that fits in the monitor's usable area with its frame and title bar visible. If none fits, the window MUST be the largest 16:9 size that does fit.
- **FR-007**: In windowed mode, the player MUST be able to resize and maximise the window freely. The window MUST NOT be forced back to 16:9 during or after a resize. The play area inside it MUST follow FR-001 at every size.
- **FR-008**: Switching between Windowed and Full screen MUST take effect right away without restarting the game, and MUST NOT lose the game in progress.
- **FR-009**: The Windowed / Full screen choice MUST be saved alongside the game's other settings and restored the next time the game starts.
- **FR-010**: On first launch, or if the setting can't be read, the desktop game MUST start windowed at the size given in FR-006.
- **FR-011**: On mobile and web builds, the display setting MUST NOT be shown. On web builds, FR-001 to FR-003 still apply. On mobile builds, FR-012 and FR-013 apply in place of FR-001 and FR-002, and FR-003 still applies.
- **FR-012**: On the Android and iOS apps, the game MUST fill the screen, scaled evenly so that 1280×720 design units fit, with the spare length along the longer side given to the layout. The layout MUST keep the arrangement of FR-001's 16:9 layout (the same regions in the same order) and MUST grow, not shrink, on wider or taller screens, up to 1760×990 design units. Past that size it MUST stop growing and stay centred, with the game's backdrop around it.
- **FR-013**: On the Android and iOS apps, every control and every piece of text MUST stay inside the device's safe area (clear of notches, rounded corners and the home indicator).

### Key Entities

- **Display mode setting**: the player's desktop choice, either Windowed or Full screen. It is saved with the existing settings (motion preference, ground, last game options). Window size and position are not saved.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On desktop and web, on each of six test shapes (16:9, 16:10, 21:9, 4:3, 9:16, and a window dragged to an odd size), every game screen keeps its designed 16:9 proportions, with 0 stretched, clipped or overlapping elements.
- **SC-006**: On the mobile test shapes (16:9 phone, 16:9 small phone, 19.5:9 notched phone held both ways, 4:3 tablet), every game screen fills the screen with no bars, and 0 elements are stretched, clipped, overlapping or outside the safe area.
- **SC-002**: A player can switch between Windowed and Full screen with one key press or one setting change, and the switch is visible within 1 second.
- **SC-003**: The Windowed / Full screen choice is restored correctly after a restart in 100% of test runs.
- **SC-004**: On 720p, 1080p, 1440p and 4K monitors, the first-launch window fits fully on screen with its title bar visible in 100% of test runs.
- **SC-005**: Across a full game played windowed, maximised and in full screen, every click and drag lands on the intended card or button.

## Assumptions

- 16:9 is the intended layout, taken from the game's current 1280×720 design size.
- "Mobile" means the Android and iOS apps. A phone's browser runs the web build and counts as web.
- Full screen means borderless windowed fullscreen, not exclusive fullscreen. Exclusive fullscreen isn't offered.
- Desktop means Windows first. macOS and Linux follow the same rules where those platforms allow.
- The Windowed / Full screen toggle goes in the existing settings panel, next to the motion and ground choices. No new screen is needed.
- The project has no desktop export preset yet. Adding one is part of delivering this feature, but this spec doesn't define it.
- The border colour is a single plain colour (or the existing dark stone tone), not new artwork.
