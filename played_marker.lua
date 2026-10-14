-- Boss Blind Shop Sign
-- Copyright (C) 2026 Jonathan Bowers (GiefKid)
-- Licensed under the GNU General Public License v3.0. See the LICENSE file.

-- Deck view preview: cards the upcoming boss will debuff (suit, face, The Pillar)
-- get the vanilla debuff X outside of battle.

BossBlindShopSign = BossBlindShopSign or {}

-- upcoming boss's G.P_BLINDS entry, or nil if there's nothing to preview
-- (no boss yet, or we're in the fight and the real debuff already shows)
function BossBlindShopSign.get_previewed_boss()
    if not (G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_choices) then
        return nil
    end
    if G.GAME.blind and G.GAME.blind.in_blind then
        return nil
    end
    -- Chicot disables the boss
    if BossBlindShopSign.chicot_active and BossBlindShopSign.chicot_active() then
        return nil
    end
    local key = G.GAME.round_resets.blind_choices['Boss']
    return key and G.P_BLINDS[key] or nil
end

-- would the boss debuff this card? same checks as Blind:debuff_card, minus the
-- ones that need the fight to be live
function BossBlindShopSign.card_previewed_debuffed(card, blind)
    if not (card and card.playing_card and blind) then return false end
    -- Verdant Leaf debuffs every card until a joker is sold
    if blind.key == 'bl_final_leaf' then return true end
    local debuff = blind.debuff
    if debuff and debuff.suit and card:is_suit(debuff.suit, true) then return true end
    if debuff and debuff.is_face == 'face' and card:is_face(true) then return true end
    if blind.key == 'bl_pillar' and card.ability and card.ability.played_this_ante then return true end
    -- rank debuffs, no vanilla boss uses these but modded ones can
    if debuff and debuff.value and card.base and debuff.value == card.base.value then return true end
    if debuff and debuff.nominal and card.base and debuff.nominal == card.base.nominal then return true end
    return false
end

-- does the upcoming boss debuff any of our cards? skips face down cards outside the deck
function BossBlindShopSign.deck_has_previewed_debuff()
    local blind = BossBlindShopSign.get_previewed_boss()
    if not (blind and G.playing_cards) then return false end
    for _, c in ipairs(G.playing_cards) do
        local hidden = c.area ~= G.deck and (c.facing == 'back' or c.sprite_facing == 'back')
        if not hidden then
            local ok, debuffed = pcall(BossBlindShopSign.card_previewed_debuffed, c, blind)
            if ok and debuffed then return true end
        end
    end
    return false
end

-- Wrap copy_card: the deck view (G.VIEWING_DECK) builds display copies via copy_card.
-- Forward every argument (a modded variant calls it with 6) and only touch the copy.
local _bss_orig_copy_card = copy_card
function copy_card(...)
    local other = ...
    -- outside the deck view, plain vanilla copy
    if not G.VIEWING_DECK then return _bss_orig_copy_card(...) end
    local ok, c = pcall(_bss_orig_copy_card, ...)
    if not ok then
        -- set_ability crashes if config.center is nil (some mods leave cards like that).
        -- fall back to a plain c_base card so the deck view doesn't crash
        sendWarnMessage('copy_card failed, using fallback: '..tostring(c), 'BossBlindShopSign')
        if other and other.T then
            c = Card(other.T.x, other.T.y, G.CARD_W, G.CARD_H,
                G.P_CARDS.empty, G.P_CENTERS.c_base)
        else
            return nil
        end
    end
    if c and G.VIEWING_DECK and other and BossBlindShopSign.opt('show_debuffed_cards') then
        -- other mods patch is_suit/is_face sometimes, don't let that crash the deck view
        local blind = BossBlindShopSign.get_previewed_boss()
        if blind then
            local ok_preview, debuffed = pcall(BossBlindShopSign.card_previewed_debuffed, other, blind)
            -- our own X (bbss_preview_x DrawStep), not .debuff, so it can have its own color
            if ok_preview and debuffed then
                c.bbss_preview_x = true
            end
        end
    end
    return c
end
