-- Boss Shop Sign
-- Copyright (C) 2026 Jonathan Bowers (GiefKid)
-- Licensed under the GNU General Public License v3.0. See the LICENSE file.

-- Deck-view preview for The Pillar boss blind.
-- When the current ante's boss is The Pillar and we're out of battle, cards that
-- have been played this ante get the vanilla debuff "X" shader in the deck view —
-- a preview of exactly which cards The Pillar will debuff (blind.lua: The Pillar
-- debuffs any card with ability.played_this_ante). Appended to button_callbacks.lua,
-- which loads after common_events.lua so copy_card is already defined.

BossShopSign = BossShopSign or {}

-- True when the deck view should preview The Pillar's debuff.
function BossShopSign.pillar_preview_active()
    if not (G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_choices) then
        return false
    end
    -- Boss this ante must be The Pillar.
    if G.GAME.round_resets.blind_choices['Boss'] ~= 'bl_pillar' then
        return false
    end
    -- Out of battle only: during the fight the real debuff already shows.
    if G.GAME.blind and G.GAME.blind.in_blind then
        return false
    end
    return true
end

-- Wrap copy_card: the deck view (G.VIEWING_DECK) builds display copies via copy_card.
-- Forward every argument (a modded variant calls it with 6) and only touch the copy.
local _bss_orig_copy_card = copy_card
function copy_card(...)
    local other = ...
    local ok, c = pcall(_bss_orig_copy_card, ...)
    if not ok then
        -- card.lua:set_ability crashes when other.config.center is nil (e.g. after certain
        -- SMODS/mod operations leave a card in an invalid state). Fall back to a bare c_base
        -- card so callers that immediately set properties (copy.greyed, etc.) don't cascade-crash.
        sendWarnMessage('copy_card failed, using fallback: '..tostring(c), 'BossShopSign')
        if other and other.T then
            c = Card(other.T.x, other.T.y, G.CARD_W, G.CARD_H,
                G.P_CARDS.empty, G.P_CENTERS.c_base)
        else
            return nil
        end
    end
    if c and G.VIEWING_DECK
        and other and other.ability and other.ability.played_this_ante
        and BossShopSign.pillar_preview_active() then
        c.debuff = true
    end
    return c
end
