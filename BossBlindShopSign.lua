-- Boss Blind Shop Sign - SMODS main file
-- Copyright (C) 2026 Jonathan Bowers (GiefKid)
-- Licensed under the GNU General Public License v3.0. See the LICENSE file.

-- Most of the UI is in the lovely-patched files. This has the options menu and deck X.

BossBlindShopSign = BossBlindShopSign or {}

local bbss_mod = SMODS.current_mod

local function bbss_save_config()
    SMODS.save_mod_config(bbss_mod)
end

-- copy of the vanilla debuff shader where the X color is a hue (see assets/shaders)
SMODS.Shader({ key = 'bbss_debuff', path = 'bbss_debuff.fs' })

-- X colors to pick from, hue is 0-1 like the shader's HSL
BossBlindShopSign.X_COLOURS = {
    { key = 'red',    name = 'Red',    hue = 0    },
    { key = 'orange', name = 'Orange', hue = 0.08 },
    { key = 'yellow', name = 'Yellow', hue = 0.16 },
    { key = 'green',  name = 'Green',  hue = 0.36 },
    { key = 'blue',   name = 'Blue',   hue = 0.58 },
}

local function bbss_colour_index(key)
    for i, c in ipairs(BossBlindShopSign.X_COLOURS) do
        if c.key == key then return i end
    end
    return 1
end

-- draw our X on a sprite in the color picked for option_key
local bbss_send = { 0, 1 }
function BossBlindShopSign.draw_x(sprite, option_key, send, no_tilt)
    local c = BossBlindShopSign.X_COLOURS[bbss_colour_index(BossBlindShopSign.opt(option_key))]
    bbss_send[1] = c.hue
    bbss_send[2] = send and send[2] or 1
    sprite:draw_shader('bbss_debuff', nil, bbss_send, no_tilt)
end

function G.FUNCS.bbss_cycle_colour(args)
    bbss_mod.config[args.cycle_config.bbss_key] = BossBlindShopSign.X_COLOURS[args.to_key].key
    bbss_save_config()
end

function BossBlindShopSign.settings_nodes()
    local cfg = bbss_mod.config
    local function toggle(label, key, info, colour_key)
        local t = create_toggle({
            label     = label,
            ref_table = cfg,
            ref_value = key,
            info      = info,
            callback  = bbss_save_config,
        })
        if not colour_key then
            return {n=G.UIT.R, config={align='cm', padding=0.08}, nodes={t}}
        end
        local names = {}
        for i, c in ipairs(BossBlindShopSign.X_COLOURS) do names[i] = c.name end
        return {n=G.UIT.R, config={align='cm', padding=0.08}, nodes={
            {n=G.UIT.C, config={align='cm'}, nodes={t}},
            {n=G.UIT.C, config={align='cm'}, nodes={
                create_option_cycle({
                    options        = names,
                    current_option = bbss_colour_index(BossBlindShopSign.opt(colour_key)),
                    opt_callback   = 'bbss_cycle_colour',
                    bbss_key       = colour_key,
                    w = 1.8, scale = 0.8,
                })
            }},
        }}
    end
    return {
        toggle("Show Upcoming Debuffed Cards", 'show_debuffed_cards', {
            "Deck view marks cards the upcoming",
            "boss will debuff with the X.",
        }, 'debuffed_cards_colour'),
        toggle("Show Debuff Reminder on Deck", 'show_deck_reminder', {
            "X on the deck pile when the upcoming",
            "boss will debuff at least one of your cards.",
        }, 'deck_reminder_colour'),
        toggle("Spawn Shop Sign in Center", 'spawn_in_center', {
            "The sign fades in big at the center of the",
            "screen, then shrinks as it flies home.",
        }),
    }
end

function bbss_mod.config_tab()
    return {
        n = G.UIT.ROOT,
        config = { r = 0.1, minw = 7, minh = 4, align = 'cm', padding = 0.2,
                   colour = G.C.BLACK, emboss = 0.05 },
        nodes = BossBlindShopSign.settings_nodes(),
    }
end

-- gear button on the sign
function G.FUNCS.bbss_open_settings(e)
    if e and e.states then
        if e.states.hover   then e.states.hover.is   = false end
        if e.states.collide then e.states.collide.is = false end
    end
    local contents = {
        {n=G.UIT.R, config={align='cm', padding=0.1}, nodes={
            {n=G.UIT.T, config={text='Boss Blind Shop Sign', scale=0.5, colour=G.C.UI.TEXT_LIGHT, shadow=true}}
        }},
    }
    for _, node in ipairs(BossBlindShopSign.settings_nodes()) do contents[#contents + 1] = node end
    G.FUNCS.overlay_menu{
        definition = create_UIBox_generic_options({ back_func = 'exit_overlay_menu', contents = contents })
    }
end

-- rebuild the sign when Chicot is bought/sold, and check if the deck X should show
local _bss_orig_game_update = Game.update
function Game:update(dt)
    _bss_orig_game_update(self, dt)
    if G.STAGE ~= G.STAGES.RUN then
        BossBlindShopSign.deck_x = false
        return
    end
    if BossBlindShopSign.sign_chicot ~= nil
        and BossBlindShopSign.chicot_active() ~= BossBlindShopSign.sign_chicot then
        BossBlindShopSign.refresh_sign()
    end
    BossBlindShopSign.deck_x = BossBlindShopSign.in_shop_context()
        and BossBlindShopSign.opt('show_deck_reminder')
        and BossBlindShopSign.deck_has_previewed_debuff()
end

-- X on the deck. Only draw on the back, drawing on the front would reveal the card
SMODS.DrawStep({
    key   = 'bbss_deck_x',
    order = 71,
    func  = function(self, layer)
        if not BossBlindShopSign.deck_x then return end
        if not (G.deck and self.area == G.deck and self == G.deck.cards[1]) then return end
        -- no tilt, otherwise it doesn't line up with the deck
        if self.children.back then
            BossBlindShopSign.draw_x(self.children.back, 'deck_reminder_colour', self.ARGS.send_to_shader, true)
        end
    end,
    conditions = { vortex = false, facing = 'back' },
})

-- X on deck view copies the upcoming boss will debuff (flag set in played_marker.lua)
SMODS.DrawStep({
    key   = 'bbss_preview_x',
    order = 71,
    func  = function(self, layer)
        if not self.bbss_preview_x then return end
        BossBlindShopSign.draw_x(self.children.center, 'debuffed_cards_colour', self.ARGS.send_to_shader)
        if self.children.front and (self.ability.delayed or not self:should_hide_front()) then
            BossBlindShopSign.draw_x(self.children.front, 'debuffed_cards_colour', self.ARGS.send_to_shader)
        end
    end,
    conditions = { vortex = false, facing = 'front' },
})
