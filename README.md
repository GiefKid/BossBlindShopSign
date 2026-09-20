# Boss Shop Sign

A [Balatro](https://www.playbalatro.com/) mod (via [Steamodded](https://github.com/Steamodded/smods) + [Lovely](https://github.com/ethangreen-dev/lovely-injector)) that replaces the shop sign with a live preview of the upcoming boss blind and other info that you'd normally have to leave the shop or open a new window to access. Although other more complicated versions of this type of mod that exist like Next Ante or UnBlind, I wanted to create one that lives in the shop, has a very simple display of the current boss blind, the required score, skip tags, and which blind the user is currently on, without having to leave the shop or open another window to obtain that info.

## Features

- **Boss blind preview** on the shop sign: name, description, and sprite for the boss blind you're heading toward, colour-coded by which blind (Small/Big/Boss) is currently upcoming.
- **Skip-tag icons** flanking the boss sprite, showing any Small/Big blind tags you've skipped, dimmed once that blind has been passed.
- **Chip requirement in the shop**: the round-info panel shows the *next* blind's chip requirement (colour-matched to blind type) instead of the last round's score, relabelled "Req. / Score".
- **Improved Deck Preview**: When the upcoming boss is the Pillar, the deck view marks cards previously played this ante with the "X" debuff.

## Installation

1. Install [Steamodded](https://github.com/Steamodded/smods) and [Lovely](https://github.com/ethangreen-dev/lovely-injector).
2. Copy this folder into your Balatro `Mods` directory as `BossShopSign`.

## Files

| File | Purpose |
|---|---|
| `BossShopSign.json` | Steamodded mod manifest |
| `BossShopSign.lua` | SMODS registration entry point |
| `lovely.toml` | Lovely patches that wire the mod into the game's UI/event code |
| `ui.lua` | Boss blind sign UI (patched into `functions/UI_definitions.lua`) |
| `chip_ui_hook.lua` | Shop chip-requirement display hook |
| `played_marker.lua` | The Pillar deck-view preview |

## License

GPL-3.0 — see [LICENSE](LICENSE).
