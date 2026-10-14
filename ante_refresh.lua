-- Boss Blind Shop Sign
-- Copyright (C) 2026 Jonathan Bowers (GiefKid)
-- Licensed under the GNU General Public License v3.0. See the LICENSE file.

-- Rebuild the sign if the ante changes mid-shop (Hieroglyph, Petroglyph, mods).
-- Orbital Tag hands are stored per ante, so the old sign would show the wrong hand.

-- Only while the shop is up. G.SHOP_SIGN isn't nil'd when you quit a run from the
-- shop, so the boss-win ease_ante would build a sign that never gets removed.
-- Also skips Cryptid's ://RUN stub (no VT), and signs from other mods (UnBlind).
local function bss_sign_is_live()
    local old = G.SHOP_SIGN
    return old and old.bbss_sign and not old.REMOVED and old.VT and G.shop and not G.shop.REMOVED
        and G.STAGE == G.STAGES.RUN
end

function BossBlindShopSign.refresh_sign()
    local old = G.SHOP_SIGN
    if not (bss_sign_is_live() and G.HUD) then return end
    -- Skip if the sign is sliding out (leaving the shop sets offset.y to -15)
    if not (old.alignment and old.alignment.offset and old.alignment.offset.y > -1) then return end
    local row_blind = G.HUD:get_UIE_by_ID('row_blind')
    if not row_blind then return end

    G.SHOP_SIGN = UIBox{
        definition = G.UIDEF.BossBlindShopSign_display(),
        config = {
            align = "cm",
            offset = {x = 0, y = old.alignment.offset.y},
            major = row_blind,
            bond = 'Weak'
        }
    }
    G.SHOP_SIGN.bbss_sign = true
    -- Start where the old sign was so it doesn't fly in from somewhere else
    G.SHOP_SIGN.VT.x, G.SHOP_SIGN.VT.y = old.VT.x, old.VT.y
    old:remove()
    G.SHOP_SIGN:juice_up(0.05, 0.03)
end

local _orig_ease_ante = ease_ante
function ease_ante(mod, ...)
    local ret = _orig_ease_ante(mod, ...)
    -- ease_ante changes the ante inside an event, so queue ours after it
    if bss_sign_is_live() then
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = function()
                BossBlindShopSign.refresh_sign()
                return true
            end
        }))
    end
    return ret
end
