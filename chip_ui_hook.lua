-- Boss Shop Sign
-- Copyright (C) 2026 Jonathan Bowers (GiefKid)
-- Licensed under the GNU General Public License v3.0. See the LICENSE file.

-- Hook chip_UI_set to display next blind chip requirement in shop (colored by type), vanilla otherwise.
-- Also relabels "Round / score" → "Req. / Score" while in the shop or a booster pack.

-- True when we're in the shop or any booster pack opened from it.
local function bss_in_shop_context()
    local s = G.STATE
    local S = G.STATES
    return s == S.SHOP
        or s == S.SMODS_BOOSTER_OPENED
        or s == S.TAROT_PACK
        or s == S.PLANET_PACK
        or s == S.SPECTRAL_PACK
        or s == S.STANDARD_PACK
        or s == S.BUFFOON_PACK
end

-- Returns the appropriate text colour for the chip count: blue/gold/red by blind type.
local function bss_next_blind_colour()
    if not (G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_states) then
        return G.C.RED
    end
    local states = G.GAME.round_resets.blind_states
    if states['Big'] == 'Defeated' or states['Big'] == 'Skipped' then
        return G.C.RED       -- Boss blind next
    elseif states['Small'] == 'Defeated' or states['Small'] == 'Skipped' then
        return G.C.GOLD      -- Big Blind next
    else
        return G.C.BLUE      -- Small Blind next
    end
end

-- Safely update a static T node's displayed text in-place.
local function bss_set_label_text(node, new_text)
    if not (node and node.config and node.config.text ~= new_text) then return end
    node.config.text = new_text
    if node.config.text_drawable then
        node.config.text_drawable:set(new_text)
    end
end

-- Traverse from chip_UI_count (e) to the two label T nodes.
-- UIElements store children in .children (integer array, not .nodes).
local function bss_find_label_nodes(e)
    local outer_c = e.parent and e.parent.parent
    if not (outer_c and outer_c.children) then return nil, nil end
    local label_c = outer_c.children[1]
    if not (label_c and label_c.children) then return nil, nil end
    local row1 = label_c.children[1]
    local row2 = label_c.children[2]
    local top = row1 and row1.children and row1.children[1]
    local bot = row2 and row2.children and row2.children[1]
    return top, bot
end

local _orig_chip_UI_set = G.FUNCS.chip_UI_set
G.FUNCS.chip_UI_set = function(e)
    local top, bot = bss_find_label_nodes(e)

    if bss_in_shop_context() then
        local next_chips = BossShopSign.get_next_blind_chips()
        if next_chips and next_chips > 0 then
            local new_text = number_format(next_chips)
            if G.GAME.chips_text ~= new_text then
                e.config.scale = math.min(0.8, scale_number(next_chips, 1.1))
                G.GAME.chips_text = new_text
            end
            e.config.colour = bss_next_blind_colour()
            bss_set_label_text(top, 'Req.')
            bss_set_label_text(bot, 'Score')
            return
        end
    end

    e.config.colour = G.C.WHITE
    bss_set_label_text(top, localize('k_round'))
    bss_set_label_text(bot, localize('k_lower_score'))
    _orig_chip_UI_set(e)
end
