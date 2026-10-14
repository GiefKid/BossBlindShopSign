-- Boss Blind Shop Sign
-- Copyright (C) 2026 Jonathan Bowers (GiefKid)
-- Licensed under the GNU General Public License v3.0. See the LICENSE file.

BossBlindShopSign = BossBlindShopSign or {}

-- option value, with defaults from config.lua
local BBSS_DEFAULTS = {
    show_debuffed_cards   = true,
    debuffed_cards_colour = 'red',
    show_deck_reminder    = true,
    deck_reminder_colour  = 'red',
    spawn_in_center       = false,
}
function BossBlindShopSign.opt(key)
    local m = SMODS and SMODS.Mods and SMODS.Mods.BossBlindShopSign
    local v = m and m.config and m.config[key]
    if v == nil then return BBSS_DEFAULTS[key] end
    return v
end

-- Let a sprite in a UIT.O slot be dragged like the in-round boss chip.
-- It's bonded Strong to its slot, which would snap it back, so the bond goes
-- Weak while held and until it glides home.
function BossBlindShopSign.make_draggable(sprite)
    sprite.states.drag.can = true
    sprite.states.click.can = false
    sprite.move = function(self, dt)
        if self.states.drag.is then
            if self.FRAME.MOVE >= G.FRAMES.MOVE then return end
            self.FRAME.MOVE = G.FRAMES.MOVE
            self:move_juice(dt)
            self:move_xy(dt)
            self:move_r(dt, self.velocity)
            self:move_scale(dt)
            self:calculate_parrallax()
            self.bbss_returning = true
            self.role.xy_bond = 'Weak'
            return
        end
        Moveable.move(self, dt)
        if self.bbss_returning and self.VT.x == self.T.x and self.VT.y == self.T.y then
            self.bbss_returning = nil
            self.role.xy_bond = 'Strong'
        end
    end
end

-- Skip tag icon for 'Small'/'Big', with hover popups like create_UIBox_blind_tag.
-- Always a fixed-width slot (empty if no tag) so the boss icon stays centered.
-- dimmed = that blind is already passed
function BossBlindShopSign.make_skip_tag_node(blind_choice, dimmed)
    -- fixed width so the boss icon stays centered
    local function slot(content)
        return {n=G.UIT.C, config={align='bm', minw=1.0, padding=0.03}, nodes = content or {}}
    end
    if not (G.GAME and G.GAME.round_resets) then return slot() end
    G.GAME.round_resets.blind_tags = G.GAME.round_resets.blind_tags or {}
    local key = G.GAME.round_resets.blind_tags[blind_choice]
    if not key then return slot() end

    -- Orbital Tag crashes if orbital_choices[ante] is nil, and the game only fills
    -- it at blind select. Fill it the same way here so the hand matches later.
    -- Fill all three in Small/Big/Boss order like the game does, or the seed draws
    -- land on the wrong blind and the hand differs from an unmodded run.
    if key == 'tag_orbital' then
        local ante = G.GAME.round_resets.ante
        G.GAME.orbital_choices = G.GAME.orbital_choices or {}
        G.GAME.orbital_choices[ante] = G.GAME.orbital_choices[ante] or {}
        for _, type in ipairs({'Small', 'Big', 'Boss'}) do
            if not G.GAME.orbital_choices[ante][type] then
                local _poker_hands = {}
                for k, v in pairs(G.GAME.hands) do
                    if SMODS.is_poker_hand_visible(k) then _poker_hands[#_poker_hands + 1] = k end
                end
                G.GAME.orbital_choices[ante][type] = pseudorandom_element(_poker_hands, pseudoseed('orbital'))
            end
        end
    end

    local tag = Tag(key, nil, blind_choice)
    local tag_ui, tag_sprite = tag:generate_UI(0.7)
    tag_sprite.states.collide.can = true
    BossBlindShopSign.make_draggable(tag_sprite)

    -- force_focus draws a black square behind the tag, turn it off
    tag_sprite.config.force_focus = false
    if tag_sprite.states and tag_sprite.states.focus then
        tag_sprite.states.focus.can = false
        tag_sprite.states.focus.is  = false
    end

    -- passed blinds draw at half alpha (overlaying black made a solid square)
    if dimmed then
        tag_sprite.bbss_dim = 0.5   -- for center_spawn.lua's fade
        tag_sprite.draw = function(_self)
            if not _self.states.visible then return end
            prep_draw(_self, 1)
            love.graphics.scale(1 / _self.scale_mag)
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.draw(_self.atlas.image, _self.sprite, 0, 0, 0,
                _self.VT.w / _self.T.w, _self.VT.h / _self.T.h)
            love.graphics.pop()
        end
    end

    -- Keep a reference so the tag object survives for the life of the UIBox.
    BossBlindShopSign.skip_tags = BossBlindShopSign.skip_tags or {}
    BossBlindShopSign.skip_tags[blind_choice] = tag

    -- minw kept small so the two flanking tags don't widen the sign past its
    -- fixed 4.72 body width.
    return slot({
        {n=G.UIT.R, config={id='bss_tag_'..blind_choice, align='cm', padding=0.04,
            can_collide=true, ref_table=tag_sprite}, nodes={
            {n=G.UIT.C, config={align='cm', minh=0.85}, nodes={tag_ui}},
        }},
    })
end

-- own a working Chicot (not one being sold)
function BossBlindShopSign.chicot_active()
    if not (G.jokers and G.jokers.cards) then return false end
    for _, j in ipairs(SMODS.find_card('j_chicot')) do
        if not j.getting_sliced then return true end
    end
    return false
end

-- Description vars for the boss. The Ox's default vars just say "(most played hand)",
-- so use the real hand like the blind select screen does. Some modded loc_vars need
-- G.GAME.blind, which isn't set in the shop, so fall back to collection_loc_vars.
function BossBlindShopSign.blind_vars(blind)
    if blind.key == 'bl_ox' then
        local hand = G.GAME.current_round and G.GAME.current_round.most_played_poker_hand or 'High Card'
        return {localize(hand, 'poker_hands')}
    end
    for _, f in ipairs({'loc_vars', 'collection_loc_vars'}) do
        if type(blind[f]) == 'function' then
            local ok, res = pcall(blind[f], blind)
            if ok and res and res.vars then return res.vars end
        end
    end
    return blind.vars
end

function G.UIDEF.BossBlindShopSign_display()
    local boss_key = G.GAME.round_resets.blind_choices['Boss']
    local blind = G.P_BLINDS[boss_key]

    if not blind then
        -- Fallback to original shop sign if blind data is unavailable
        local shop_sign = AnimatedSprite(0, 0, 4.4, 2.2, G.ANIMATION_ATLAS['shop_sign'])
        shop_sign:define_draw_steps({{shader = 'dissolve', shadow_height = 0.05}, {shader = 'dissolve'}})
        return {n=G.UIT.ROOT, config={colour=G.C.DYN_UI.MAIN, emboss=0.05, align='cm', r=0.1, padding=0.1}, nodes={
            {n=G.UIT.R, config={align='cm', padding=0.1, minw=4.72, minh=3.1, colour=G.C.DYN_UI.DARK, r=0.1}, nodes={
                {n=G.UIT.R, config={align='cm'}, nodes={{n=G.UIT.O, config={object=shop_sign}}}},
                {n=G.UIT.R, config={align='cm'}, nodes={{n=G.UIT.O, config={object=DynaText({string={localize('ph_improve_run')}, colours={lighten(G.C.GOLD, 0.3)}, shadow=true, rotate=true, float=true, bump=true, scale=0.5, spacing=1, pop_in=1.5, maxw=4.3})}}}}
            }}
        }}
    end

    local states = G.GAME.round_resets.blind_states
    local display_state, state_colour
    BossBlindShopSign.sign_chicot = BossBlindShopSign.chicot_active()
    if states['Big'] == 'Defeated' or states['Big'] == 'Skipped' then
        display_state = BossBlindShopSign.sign_chicot and 'Boss Disabled' or 'Upcoming'
        state_colour  = G.C.RED
    elseif states['Small'] == 'Defeated' or states['Small'] == 'Skipped' then
        display_state = 'Big Blind'
        state_colour  = get_blind_main_colour('bl_big')
    else
        display_state = 'Small Blind'
        state_colour  = get_blind_main_colour('bl_small')
    end

    local blind_sprite = AnimatedSprite(0, 0, 1.5, 1.5,
        G.ANIMATION_ATLAS[blind.atlas] or G.ANIMATION_ATLAS['blind_chips'], blind.pos)
    BossBlindShopSign.blind_sprite = blind_sprite
    blind_sprite:define_draw_steps({{shader='dissolve', shadow_height=0.05}, {shader='dissolve'}})
    blind_sprite.float = true
    blind_sprite.states.hover.can = true
    blind_sprite.states.collide.can = true
    blind_sprite.config = {blind = blind, force_focus = true}

    BossBlindShopSign.make_draggable(blind_sprite)
    blind_sprite.hover = function()
        if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then
            if not blind_sprite.hovering and blind_sprite.states.visible then
                blind_sprite.hovering = true
                blind_sprite.hover_tilt = 3
                blind_sprite:juice_up(0.05, 0.02)
                play_sound('chips1', math.random() * 0.1 + 0.55, 0.12)
                blind_sprite.config.h_popup = create_UIBox_blind_popup(blind, blind.discovered, BossBlindShopSign.blind_vars(blind))
                blind_sprite.config.h_popup_config = {align='bm', offset={x=0, y=0.1}, parent=blind_sprite}
                Node.hover(blind_sprite)
            end
        end
        blind_sprite.stop_hover = function()
            blind_sprite.hovering = false
            Node.stop_hover(blind_sprite)
            blind_sprite.hover_tilt = 0
        end
    end

    local desc_lines = localize{type='raw_descriptions', key=blind.key, set='Blind',
        vars = BossBlindShopSign.blind_vars(blind)}
    local blind_name = localize{type='name_text', key=blind.key, set='Blind'}

    local desc_nodes = {}
    if desc_lines and type(desc_lines) == 'table' then
        for _, line in ipairs(desc_lines) do
            desc_nodes[#desc_nodes + 1] = {
                n=G.UIT.R, config={align='cm'},
                nodes={{n=G.UIT.T, config={text=line, scale=0.3, colour=G.C.UI.TEXT_LIGHT, shadow=true}}}
            }
        end
    end

    -- skip tags on each side of the boss icon, dimmed once that blind is passed
    local small_dim = (display_state ~= 'Small Blind')
    local big_dim   = (display_state == 'Upcoming' or display_state == 'Boss Disabled')
    local left_node  = BossBlindShopSign.make_skip_tag_node('Small', small_dim)
    local right_node = BossBlindShopSign.make_skip_tag_node('Big', big_dim)

    return {
        n = G.UIT.ROOT,
        config = {colour=state_colour, emboss=0.05, align='cm', r=0.1, padding=0.1},
        nodes = {{
            n = G.UIT.C,
            config = {align='cm', padding=0.1, minw=4.72, minh=3.1, colour=G.C.DYN_UI.DARK, r=0.1},
            nodes = {
                -- Current blind badge ("Small Blind" / "Big Blind" / "Upcoming" / "Boss Disabled")
                {n=G.UIT.R, config={align='cm', padding=0.07, colour=state_colour, r=0.1, emboss=0.05},
                    nodes={{n=G.UIT.T, config={text=display_state, scale=0.45, colour=G.C.WHITE, shadow=true}}}},

                -- Blind name on dark pill
                {n=G.UIT.R, config={align='cm', padding=0.06, colour=G.C.BLACK, r=0.1, minw=3.8, emboss=0.05},
                    nodes={{n=G.UIT.T, config={text=blind_name, scale=0.42, colour=G.C.WHITE, shadow=true}}}},

                {n=G.UIT.R, config={align='cm', padding=0.08}, nodes={
                    left_node or nil,
                    {n=G.UIT.C, config={align='cm'}, nodes={{n=G.UIT.O, config={object=blind_sprite}}}},
                    right_node or nil,
                }},

                -- description + settings gear (empty left cell keeps it centered)
                {n=G.UIT.R, config={align='cm', padding=0.04}, nodes={
                    {n=G.UIT.C, config={align='cm', minw=0.77}, nodes={}},
                    #desc_nodes > 0 and {n=G.UIT.C, config={align='cm'}, nodes=desc_nodes} or nil,
                    {n=G.UIT.C, config={align='cm', minw=0.77}, nodes={
                        {n=G.UIT.C, config={button='bbss_open_settings', align='cm', minh=0.28, minw=0.28,
                            padding=0.02, r=0.05, colour=G.C.GREY, hover=true, shadow=true}, nodes={
                            {n=G.UIT.O, config={object=SMODS.create_sprite(0, 0, 0.24, 0.24, 'mod_tags', {x=2, y=0})}}
                        }},
                    }},
                }},
            }
        }}
    }
end

-- Next blind chip requirement.
function BossBlindShopSign.get_next_blind_chips()
    if not (G.GAME and G.GAME.round_resets) then return nil end
    local states  = G.GAME.round_resets.blind_states
    local choices = G.GAME.round_resets.blind_choices
    if not (states and choices) then return nil end
    local key
    if states['Big'] == 'Defeated' or states['Big'] == 'Skipped' then
        key = choices['Boss']
    elseif states['Small'] == 'Defeated' or states['Small'] == 'Skipped' then
        key = choices['Big'] or 'bl_big'
    else
        key = choices['Small'] or 'bl_small'
    end
    if not (key and G.P_BLINDS and G.P_BLINDS[key]) then return nil end
    local mult    = G.P_BLINDS[key].mult or 0
    local ante    = G.GAME.round_resets.ante or 1
    local scaling = G.GAME.starting_params and G.GAME.starting_params.ante_scaling or 1
    local ok, amt = pcall(get_blind_amount, ante)
    if not ok or not amt then return nil end
    return amt * mult * scaling
end
