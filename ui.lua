-- Boss Shop Sign
-- Copyright (C) 2026 Jonathan Bowers (GiefKid)
-- Licensed under the GNU General Public License v3.0. See the LICENSE file.

BossShopSign = BossShopSign or {}

-- Build a hoverable skip-tag icon slot for the given blind choice ('Small'/'Big').
-- ALWAYS returns a fixed-width slot (empty when there's no tag to show) so the
-- boss icon between the two slots stays centred. Mirrors create_UIBox_blind_tag's
-- collide/ref_table wrapping so hover popups work. `dimmed` marks a blind that's
-- already been passed, and is drawn with a faded overlay.
function BossShopSign.make_skip_tag_node(blind_choice, dimmed)
    -- Fixed-width slot; empty content keeps the boss icon centred.
    local function slot(content)
        return {n=G.UIT.C, config={align='bm', minw=1.0, padding=0.03}, nodes = content or {}}
    end
    if not (G.GAME and G.GAME.round_resets) then return slot() end
    G.GAME.round_resets.blind_tags = G.GAME.round_resets.blind_tags or {}
    local key = G.GAME.round_resets.blind_tags[blind_choice]
    if not key then return slot() end

    -- The Orbital Tag reads G.GAME.orbital_choices[ante][blind_type] in
    -- Tag:set_ability (tag.lua:113). The game only fills that table when the
    -- blind-select screen is built (create_UIBox_blind_choice). We render the tag
    -- earlier, from the shop sign, so for the upcoming ante orbital_choices[ante]
    -- is still nil and the vanilla `orbital_choices[ante][blind_type]` indexes nil
    -- and crashes. Pre-populate it here exactly as the game does: this avoids the
    -- crash and keeps the preview hand identical to the one shown at blind select
    -- (both reuse the same stored value, so only one pseudoseed('orbital') roll).
    if key == 'tag_orbital' then
        local ante = G.GAME.round_resets.ante
        G.GAME.orbital_choices = G.GAME.orbital_choices or {}
        G.GAME.orbital_choices[ante] = G.GAME.orbital_choices[ante] or {}
        if not G.GAME.orbital_choices[ante][blind_choice] then
            local _poker_hands = {}
            for k, v in pairs(G.GAME.hands) do
                if SMODS.is_poker_hand_visible(k) then _poker_hands[#_poker_hands + 1] = k end
            end
            G.GAME.orbital_choices[ante][blind_choice] = pseudorandom_element(_poker_hands, pseudoseed('orbital'))
        end
    end

    local tag = Tag(key, nil, blind_choice)
    local tag_ui, tag_sprite = tag:generate_UI(0.7)
    tag_sprite.states.collide.can = true

    -- generate_UI marks the sprite force_focus=true, which makes the O node draw
    -- a persistent focus-highlight fill behind it (the "black square"). Turn focus
    -- off so the tag renders as just its icon; hover popups still work.
    tag_sprite.config.force_focus = false
    if tag_sprite.states and tag_sprite.states.focus then
        tag_sprite.states.focus.can = false
        tag_sprite.states.focus.is  = false
    end

    -- A blind that's already been passed (dimmed) is drawn at reduced alpha so
    -- it reads as see-through/faded. We replace draw (rather than overlaying
    -- black, which just darkens the icon's button into a solid square) so only
    -- the icon itself fades, showing the panel behind it.
    if dimmed then
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
    BossShopSign.skip_tags = BossShopSign.skip_tags or {}
    BossShopSign.skip_tags[blind_choice] = tag

    -- minw kept small so the two flanking tags don't widen the sign past its
    -- fixed 4.72 body width.
    return slot({
        {n=G.UIT.R, config={id='bss_tag_'..blind_choice, align='cm', padding=0.04,
            can_collide=true, ref_table=tag_sprite}, nodes={
            {n=G.UIT.C, config={align='cm', minh=0.85}, nodes={tag_ui}},
        }},
    })
end

function G.UIDEF.BossShopSign_display()
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
    if states['Big'] == 'Defeated' or states['Big'] == 'Skipped' then
        display_state = 'Upcoming'
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
    BossShopSign.blind_sprite = blind_sprite
    blind_sprite:define_draw_steps({{shader='dissolve', shadow_height=0.05}, {shader='dissolve'}})
    blind_sprite.float = true
    blind_sprite.states.hover.can = true
    blind_sprite.states.drag.can = false
    blind_sprite.states.collide.can = true
    blind_sprite.config = {blind = blind, force_focus = true}
    blind_sprite.hover = function()
        if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then
            if not blind_sprite.hovering and blind_sprite.states.visible then
                blind_sprite.hovering = true
                blind_sprite.hover_tilt = 3
                blind_sprite:juice_up(0.05, 0.02)
                play_sound('chips1', math.random() * 0.1 + 0.55, 0.12)
                local vars = blind.vars
                if blind.loc_vars then
                    local ok, res = pcall(function() return blind:loc_vars() end)
                    if ok and res then vars = res.vars or vars end
                end
                blind_sprite.config.h_popup = create_UIBox_blind_popup(blind, blind.discovered, vars)
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

    local vars = blind.vars
    if blind.loc_vars then
        local ok, res = pcall(function() return blind:loc_vars() end)
        if ok and res then vars = res.vars or vars end
    end
    local most_played = G.GAME.current_round and G.GAME.current_round.most_played_poker_hand or 'High Card'
    local desc_lines = localize{type='raw_descriptions', key=blind.key, set='Blind',
        vars = vars or {localize(most_played, 'poker_hands')}}
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

    -- Skip-tag icons flanking the boss icon (inside the sign, no extra width).
    -- Tags for blinds already passed stay in place but dimmed:
    --   Small Blind upcoming → small (left) + big (right), both solid
    --   Big Blind upcoming   → small dimmed (left) + big solid (right)
    --   Boss upcoming        → small + big both dimmed
    local small_dim = (display_state ~= 'Small Blind')
    local big_dim   = (display_state == 'Upcoming')
    local left_node  = BossShopSign.make_skip_tag_node('Small', small_dim)
    local right_node = BossShopSign.make_skip_tag_node('Big', big_dim)

    return {
        n = G.UIT.ROOT,
        config = {colour=state_colour, emboss=0.05, align='cm', r=0.1, padding=0.1},
        nodes = {{
            n = G.UIT.C,
            config = {align='cm', padding=0.1, minw=4.72, minh=3.1, colour=G.C.DYN_UI.DARK, r=0.1},
            nodes = {
                -- Current blind badge ("Small Blind" / "Big Blind" / "Upcoming")
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

                {n=G.UIT.R, config={align='cm', padding=0.04}, nodes=desc_nodes},
            }
        }}
    }
end

-- Next blind chip requirement.
function BossShopSign.get_next_blind_chips()
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
