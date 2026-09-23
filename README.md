# Boss Shop Sign

A simple [Balatro](https://www.playbalatro.com/) mod (via [Steamodded](https://github.com/Steamodded/smods) + [Lovely](https://github.com/ethangreen-dev/lovely-injector)) that replaces the shop sign with a live preview of the upcoming boss blind.

Other versions of this UI mod already exist, but I wanted to create a simple one that lives in the shop and does not require any mouse clicks.

## Features

- **Boss blind preview** on the shop sign: name, description, and sprite for the boss blind you're heading toward, color-coded by which blind (Small/Big/Boss) is currently upcoming.
- **Skip-tag icons** flanking the boss sprite, showing any Small/Big blind tags you've skipped, dimmed once that blind has been passed.
- **Required Chip Score shows in-shop**: the round-info panel shows the *next* blind's chip requirement (color-matched to blind type) instead of the last round's score, relabeled "Req. / Score".
- **Improved Deck Preview**: When the upcoming boss debuffs cards, the deck view marks the affected cards with the "X" Debuff ahead of time — cards played this ante for The Pillar, matching-suit cards for The Club/Goad/Window/Head, and face cards for The Plant.

## Installation

1. Install [Steamodded](https://github.com/Steamodded/smods) and [Lovely Injector](https://github.com/ethangreen-dev/lovely-injector?tab=readme-ov-file#manual-installation) (both required — this mod is a Steamodded mod that also uses Lovely patches).
2. Download the [latest release](https://github.com/GiefKid/BossShopSign/releases/latest) and extract it into its own folder inside your Balatro `Mods` folder (`%appdata%\Balatro\Mods`), so you end up with `Mods\BossShopSign\BossShopSign.json` etc.
3. Launch the game. The shop sign now previews the upcoming boss blind automatically — no setup or toggling needed.

## Files

| File | Purpose |
|---|---|
| `BossShopSign.json` | Steamodded mod manifest |
| `BossShopSign.lua` | SMODS registration entry point |
| `lovely.toml` | Lovely patches that wire the mod into the game's UI/event code |
| `ui.lua` | Boss blind sign UI (patched into `functions/UI_definitions.lua`) |
| `chip_ui_hook.lua` | Shop chip-requirement display hook |
| `played_marker.lua` | Boss debuff deck-view preview |

## License

GPL-3.0 — see [LICENSE](LICENSE).
