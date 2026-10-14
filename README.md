# Boss Blind Shop Sign

A simple [Balatro](https://www.playbalatro.com/) mod (via [Steamodded](https://github.com/Steamodded/smods) + [Lovely](https://github.com/ethangreen-dev/lovely-injector)) that replaces the shop sign with a live preview of the upcoming boss blind

## Features
- **Boss blind preview** on the shop sign: name, description, and sprite for the boss blind you're heading toward, color-coded by which blind (Small/Big/Boss) is currently upcoming.
- **Skip-tag icons** flanking the boss sprite, showing any Small/Big blind tags you've skipped, dimmed once that blind has been passed.
- **Draggable icons (v1.4)**: the boss sprite and skip-tag icons on the sign can be picked up and dragged around like the in-round boss chip, and glide back into place when released.
- **Required Chip Score shows in-shop**: the round-info panel shows the *next* blind's chip requirement (color-matched to blind type) instead of the last round's score, relabeled "Req. / Score".
- **Improved Deck Preview**: When the upcoming boss debuffs cards, the Deck View marks the affected cards with the "X" Debuff. Cards played this ante for The Pillar, matching-suit cards for The Club/Goad/Window/Head, and face cards for The Plant fall under this rule. In v1.5, this is now a togglable setting, and support for Verdant Leaf was added.

## v1.5 Features
- New Settings button
  - Setting 1: **Show Upcoming Debuffed Cards**: Already in the mod (Improved Deck Preview), just wasn't able to be toggled on/off and is now color-adjustable. Default On.
  - Setting 2: **Show Debuff Reminder On Deck**: New "X" color-adjustable debuff icon on the deck when in the shop, which appears when a boss blind debuffs at least one card. Default On.
  - Setting 3: **Spawn Shop Sign in Center**: Sign spawns in center, then flies to its home, instead of sliding in from top-left. Helps the player not forget to view it. **Default Off**.
- When player owns Chicot, "Boss Disabled" now appears instead of "Upcoming". Debuffs in shop also do not appear.
- Works alongside [UnBlind](https://github.com/MeraGenio/UnBlind), using its shop sign UI, but includes Req. Score, View Deck, and Debuff Reminder features.

## v1.5 Bug Fixes
- Orbital Tag now properly updates in-shop if Hieroglyph or Petroglyph is purchased
- The Ox now shows your actual most played hand
- Req. Score now properly stays visible in all parts of the shop
- Better (but not perfect) modded boss description support (rank debuffs now supported)
- Verdant Leaf now shows properly in the Deck Preview, and triggers the X Debuff Reminder
- New Steamodded (1.0.0~BETA-1221a or newer) requirement to prevent crashes

## Installation

1. Install [Steamodded](https://github.com/Steamodded/smods) and [Lovely Injector](https://github.com/ethangreen-dev/lovely-injector?tab=readme-ov-file#manual-installation)
2. Download the [latest release](https://github.com/GiefKid/BossBlindShopSign/releases/latest) and extract it into its own folder inside your Balatro `Mods` folder (`%appdata%\Balatro\Mods`), so you end up with `Mods\BossBlindShopSign\BossBlindShopSign.json` etc.

## Files

| File | Purpose |
|---|---|
| `BossBlindShopSign.json` | Steamodded mod manifest |
| `BossBlindShopSign.lua` | SMODS registration entry point |
| `lovely.toml` | Lovely patches that wire the mod into the game's UI/event code |
| `ui.lua` | Boss blind sign UI (patched into `functions/UI_definitions.lua`) |
| `chip_ui_hook.lua` | Shop chip-requirement display hook |
| `played_marker.lua` | Boss debuff deck-view preview |

## License

GPL-3.0 -- see [LICENSE](LICENSE).
