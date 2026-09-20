-- Boss Shop Sign
-- Copyright (C) 2026 Jonathan Bowers (GiefKid)
-- Licensed under the GNU General Public License v3.0. See the LICENSE file.

-- Deck-view preview for boss blinds that debuff cards based on a static property
-- (suit, face rank) or on cards played this ante. When the upcoming boss is one
-- of these and we're out of battle, matching cards get the vanilla debuff "X"
-- shader in the deck view, mirroring blind.lua's Blind:debuff_card. Appended to
-- button_callbacks.lua, which loads after common_events.lua so copy_card is
-- already defined.

BossShopSign = BossShopSign or {}

-- Returns the upcoming boss's G.P_BLINDS entry, or nil if there isn't one to
-- preview (no boss chosen yet, or we're in the middle of the blind fight,
-- where the real debuff already shows).
function BossShopSign.get_previewed_boss()
    if not (G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_choices) then
        return nil
    end
    if G.GAME.blind and G.GAME.blind.in_blind then
        return nil
    end
    local key = G.GAME.round_resets.blind_choices['Boss']
    return key and G.P_BLINDS[key] or nil
end

-- True when `card` would be debuffed by boss blind `blind`, per blind.lua's
-- Blind:debuff_card (suit / is_face / The Pillar's played_this_ante — the only
-- conditions in the base game that don't require the fight to already be live).
function BossShopSign.card_previewed_debuffed(card, blind)
    if not (card and card.playing_card and blind) then return false end
    local debuff = blind.debuff
    if debuff and debuff.suit and card:is_suit(debuff.suit, true) then return true end
    if debuff and debuff.is_face == 'face' and card:is_face(true) then return true end
    if blind.key == 'bl_pillar' and card.ability and card.ability.played_this_ante then return true end
    return false
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
    if c and G.VIEWING_DECK and other then
        local blind = BossShopSign.get_previewed_boss()
        if blind and BossShopSign.card_previewed_debuffed(other, blind) then
            c.debuff = true
        end
    end
    return c
end
