-- Boss Blind Shop Sign
-- Copyright (C) 2026 Jonathan Bowers (GiefKid)
-- Licensed under the GNU General Public License v3.0. See the LICENSE file.

-- Optional: shop sign fades in big at the center of the screen, then shrinks as it flies home.

BossBlindShopSign = BossBlindShopSign or {}

local BBSS_FADE_TIME    = 0.25
local BBSS_HOLD_TIME    = 1.0
local BBSS_HOME_TIMEOUT = 3.0
local BBSS_BIG_SCALE    = 1.25

-- dissolve shader can't fade, so draw plain while fading in
local function bbss_fade_draw(_self)
    if not _self.states.visible then return end
    prep_draw(_self, 1)
    love.graphics.scale(1 / _self.scale_mag)
    love.graphics.setColor(1, 1, 1, (_self.bbss_dim or 1) * (_self.bbss_alpha or 1))
    love.graphics.draw(_self.atlas.image, _self.sprite, 0, 0, 0,
        _self.VT.w / _self.T.w, _self.VT.h / _self.T.h)
    love.graphics.pop()
end

function BossBlindShopSign.start_center_spawn(sign)
    if not BossBlindShopSign.opt('spawn_in_center') then return end
    if not (sign and sign.UIRoot) then return end

    -- copy colours so we can fade them, and turn off clicks/hovers until it lands
    local fades, sprites, collides = {}, {}, {}
    local function walk(uie)
        if not uie then return end
        if uie.states and uie.states.collide then
            collides[#collides + 1] = { s = uie.states.collide, can = uie.states.collide.can }
            uie.states.collide.can = false
        end
        if uie.config then
            if uie.config.colour then
                uie.config.colour = copy_table(uie.config.colour)
                fades[#fades + 1] = { col = uie.config.colour, a0 = uie.config.colour[4] or 1 }
            end
            local obj = uie.config.object
            if obj and type(obj.define_draw_steps) == 'function' then
                sprites[#sprites + 1] = { obj = obj, draw = rawget(obj, 'draw') }
                obj.bbss_alpha = 0
                obj.draw = bbss_fade_draw
                if obj.states and obj.states.collide then
                    collides[#collides + 1] = { s = obj.states.collide, can = obj.states.collide.can }
                    obj.states.collide.can = false
                end
            end
        end
        if uie.children then for _, ch in ipairs(uie.children) do walk(ch) end end
    end
    walk(sign.UIRoot)

    local function set_alpha(a)
        for _, f in ipairs(fades) do f.col[4] = f.a0 * a end
        for _, sp in ipairs(sprites) do sp.obj.bbss_alpha = a end
    end
    local function restore_sprites()
        for _, sp in ipairs(sprites) do
            sp.obj.draw = sp.draw
            sp.obj.bbss_alpha = nil
        end
    end
    set_alpha(0)

    local fx = { phase = 'held', t0 = G.TIMERS.REAL, faded = false, scale = BBSS_BIG_SCALE }
    sign.bbss_fx = fx
    sign.attention_text = true   -- draw on top of the shop

    local function pin_to_center()
        local room = G.ROOM_ATTACH.T
        sign.VT.x = room.x + room.w / 2 - sign.T.w / 2
        sign.VT.y = room.y + room.h / 2 - sign.T.h / 2
        sign.velocity.x, sign.velocity.y = 0, 0
    end

    function fx.finish()
        if fx.done then return end
        fx.done = true
        if not fx.faded then set_alpha(1); restore_sprites() end
        for _, c in ipairs(collides) do c.s.can = c.can end
        sign.attention_text = nil
        sign.bbss_fx = nil
        sign.move = nil
        sign.draw = nil
    end

    local function dist_home()
        local dx, dy = sign.T.x - sign.VT.x, sign.T.y - sign.VT.y
        return math.sqrt(dx * dx + dy * dy)
    end

    -- scale the whole sign around its center
    sign.draw = function(self)
        if fx.scale == 1 then return UIBox.draw(self) end
        local k = G.TILESCALE * G.TILESIZE
        local px = (self.VT.x + self.VT.w / 2) * k
        local py = (self.VT.y + self.VT.h / 2) * k
        love.graphics.push()
        love.graphics.translate(px, py)
        love.graphics.scale(fx.scale)
        love.graphics.translate(-px, -py)
        UIBox.draw(self)
        love.graphics.pop()
    end

    -- T stays at home the whole time; we hold VT in the center, then let the
    -- normal Weak bond pull it home (capped at card drag speed)
    pin_to_center()
    sign.move = function(self, dt)
        Moveable.move(self, dt)
        if not fx.done then
            local now = G.TIMERS.REAL
            local t = now - fx.t0
            if not fx.faded then
                if t >= BBSS_FADE_TIME then
                    set_alpha(1)
                    restore_sprites()
                    fx.faded = true
                else
                    set_alpha(t / BBSS_FADE_TIME)
                end
            end
            if fx.phase == 'held' then
                if t >= BBSS_FADE_TIME + BBSS_HOLD_TIME then
                    fx.phase = 'homing'
                    fx.t0 = now
                    fx.dist0 = dist_home()
                else
                    pin_to_center()
                end
            elseif fx.phase == 'homing' then
                local left = fx.dist0 > 0 and math.min(1, dist_home() / fx.dist0) or 0
                fx.scale = 1 + (BBSS_BIG_SCALE - 1) * left
                local home = self.VT.x == self.T.x and self.VT.y == self.T.y
                if home or t >= BBSS_HOME_TIMEOUT then fx.finish() end
            end
        end
        Moveable.move(self.UIRoot, dt)
    end
end

-- leaving the shop mid-effect: just hide it, vanilla removes it
local _bbss_orig_toggle_shop = G.FUNCS.toggle_shop
G.FUNCS.toggle_shop = function(e)
    local sign = G.SHOP_SIGN
    if sign and sign.bbss_fx and not sign.REMOVED then
        sign.bbss_fx.finish()
        sign.states.visible = false
    end
    return _bbss_orig_toggle_shop(e)
end
