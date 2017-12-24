return

{
    join = function(id)
        br.player[id] = br.funcs.player.getDataSchema()
        br.funcs.player.loadStoredData(id)
        br.funcs.timer.init(1000, br.funcs.player.updateHud, id)
        br.funcs.player.updateAura(id)

        br.player[id].newMenu = function(...)
            return br.menu.new(id, ...)
        end
        br.player[id].newTeam = function(...)
            return br.team.new(br.player[id], ...)
        end

        for k, v in pairs(br.config.roles) do
            if v.players then
                for _, sid in pairs(v.players) do
                    if sid == player(id, 'steamid') then
                        br.player[id].role = k
                    end
                end
            end
        end
    end,

    leave = function(id)
        br.funcs.player.saveStoredData(id)
        br.player[id] = br.funcs.player.getDataSchema()
        br.funcs.game.checkIfEnded()
    end,

    team = function(id, team)
        if player(id, 'team') == 0 and team > 0 then
            if br.gracePeriodTimer <= 0 then
                br.player[id].inGame = true
                br.player[id].killed = true
                br.funcs.player.updateHud(id)

                local activePlayers = 0
                for _, pl in pairs(player(0, 'table')) do
                    if br.player[pl].inGame then
                        activePlayers = activePlayers + 1
                    end
                end

                if activePlayers <= 2 then
                    parse('restart')
                end
            else
                br.player[id].inGame = true
                br.player[id].killed = false
                br.player[id].ui.lastInfo = false
                br.funcs.timer.init(10, br.funcs.player.randomSpawn, id)
            end
        elseif player(id, 'team') > 0 and team == 0 then
            br.player[id].inGame = false
            br.player[id].killed = true
        end
    end,

    startround_prespawn = function()
        br.roundEnded = false

        for _, pl in pairs(player(0, 'table')) do
            if br.player[pl].inGame then
                br.player[pl].killed = false
            end
        end
    end,

    startround = function()
        for _, timer in pairs(_G['TIMERS'] or {}) do
            br.funcs.timer.free(timer)
        end

        br.packages = {}
        for name, package in pairs(br.config.packages) do
            for i = 1, package.spawns do
                local spawnx, spawny
                repeat
                    spawnx = math.random(0, map 'xsize')
                    spawny = math.random(0, map 'ysize')
                until br.funcs.game.checkIfSpawnable(spawnx, spawny)

                local newPackage = {
                    x      = spawnx,
                    y      = spawny,
                    type   = name,
                    image  = image(package.image, 0, 0, 0),
                    config = package
                }

                imagepos(newPackage.image, spawnx * 32 + 16, spawny * 32 + 16, math.random(-180, 180))
                table.insert(br.packages, newPackage)
            end
        end

        br.gracePeriodTimer = br.config.gracePeriodSeconds
        br.gpTimerFrame     = br.config.gracePeriodSeconds > 9 and 9 or br.config.gracePeriodSeconds
        br.gpTimerFont      = image('<spritesheet:' .. br.config.fontImage .. ':100:100:m>', -1000, -1000, 2)

        local sx, sy
        repeat
            sx = math.random(0, map 'xsize')
            sy = math.random(0, map 'ysize')
        until br.funcs.game.checkIfSpawnable(sx, sy)

        br.safeZone = br.funcs.geometry.drawZone(
            sx * 32 + 16,
            sy * 32 + 16,
            (map 'xsize' > map 'ysize' and map 'xsize' or map 'ysize') * 32,
            0.35
        )
        br.shrinkStarted = false

        br.expBar = image(
            br.config.ui.expBarImage,
            br.config.ui.expBar.position[1],
            br.config.ui.expBar.position[2],
            2
        )

        for _, pl in pairs(player(0, 'table')) do
            if br.player[pl].inGame then
                br.player[pl].killed = false
                br.player[pl].spawnPosition = false
                br.player[pl].auraImage = false

                br.funcs.player.randomSpawn(pl)
                br.funcs.player.updateAura(pl)
            end

            br.player[pl].stamina = 100

            br.player[pl].ui.lastInfo = false
            for key, _ in pairs(br.player[pl].ui.images) do
                br.player[pl].ui.images[key] = false
            end
            for key, _ in pairs(br.player[pl].ui.skins.images) do
                br.player[pl].ui.skins.images[key] = false
            end

            br.funcs.player.updateHud(pl)
            br.funcs.player.saveStoredData(pl)
        end

        for _, train in pairs(br.trains) do
            train.image = image(train.config.image, 0, 0, 3)
            imagealpha(train.image, 0)

            train.running = false
            train.startedAt = 0
            train.finishesIn = 0

            br.funcs.timer.init(train.config.cycle * 1000, br.funcs.train.launch, train)
        end
    end,

    die = function(victim, killer)
        if br.gracePeriodTimer > 0 then
            br.player[victim].ui.lastInfo = false
            if br.player[victim].inGame then
                br.funcs.timer.init(10, br.funcs.player.randomSpawn, victim)
            end
        else
            br.player[victim].killed = true
            if killer > 0 and killer ~= victim then
                br.funcs.player.addExp(killer, 150)
                br.funcs.player.updateHud(killer)
            end

            parse('sv_sound "' .. br.config.killSoundFile .. '"')
            br.funcs.game.checkIfEnded()
        end

        br.funcs.player.updateHud(victim)
    end,

    second = function()
        br.gracePeriodTimer = br.gracePeriodTimer - 1
        if br.gracePeriodTimer <= 0 then
            br.gracePeriodTimer = 0
        end

        if br.gpTimerFrame == br.gracePeriodTimer then
            if br.gpTimerFrame == 9 then
                imagepos(br.gpTimerFont, 425, 140, 0)
            end

            if br.gpTimerFrame > 0 then
                imageframe(br.gpTimerFont, br.gpTimerFrame)
                imagescale(br.gpTimerFont, 2, 2)
                tween_scale(br.gpTimerFont, 900, 0.5, 0.5)
                br.gpTimerFrame = br.gpTimerFrame - 1
            else
                imageframe(br.gpTimerFont, 11)
                imagescale(br.gpTimerFont, 2, 2)
                tween_alpha(br.gpTimerFont, 1500, 0)
                tween_scale(br.gpTimerFont, 1500, 0.25, 0.25)
                br.gpTimerFrame = br.gpTimerFrame - 1
            end
        end

        if br.safeZone then
            for _, pl in pairs(player(0, 'tableliving')) do
                local x, y, health = player(pl, 'x'), player(pl, 'y'), player(pl, 'health')
                if br.funcs.geometry.distance(x, y, br.safeZone.x, br.safeZone.y)
                    > br.funcs.geometry.getZoneRadius(br.safeZone) then
                    parse('explosion ' .. x .. ' ' .. y .. ' 3 0')
                    if health - br.config.dangerAreaDamage > 0 then
                        parse('sethealth ' .. pl ..' ' .. health - br.config.dangerAreaDamage)
                    else
                        parse('customkill 0 "danger zone" ' .. pl)
                    end
                end

                if not br.player[pl].sprinting then
                    br.player[pl].stamina = br.player[pl].stamina + 2
                    if br.player[pl].stamina >= 100 then
                        br.player[pl].stamina = 100
                    end
                end
            end

            for _, ob in pairs(object(0, 'table')) do
                local x, y = object(ob, 'x'), object(ob, 'y')
                if type(object(ob, 'type')) == 'number' and object(ob, 'type') < 30 then
                    if br.funcs.geometry.distance(x, y, br.safeZone.x, br.safeZone.y)
                        > br.funcs.geometry.getZoneRadius(br.safeZone) then
                        parse('killobject ' .. ob)
                    end
                end
            end
        end

        for _, pl in pairs(player(0, 'table')) do
            br.funcs.player.updateHud(pl)
        end

        if br.gracePeriodTimer > 0 then return end

        if not br.shrinkStarted and br.safeZone then
            br.shrinkStarted = true
            br.funcs.geometry.shrinkZone(br.safeZone, br.config.finalAreaRadius * 32, br.config.areaShrinkingSpeed)
        end
    end,

    ms100 = function()
        for _, v in pairs(player(0, 'table')) do
            if player(v, 'health') > 0 then
                for _, train in pairs(br.trains) do
                    if br.funcs.train.positionInTrain(train, player(v, 'x'), player(v, 'y')) then
                        parse('customkill 0 "train" ' .. v)
                    end
                end

                if br.player[v].ui.skins.opened then
                    br.hooks.clientdata(v, 0, player(1, 'mousex'), player(1, 'mousey'))
                end
            else
                if br.player[v].ui.skins.opened then
                    reqcld(v, 0)
                end
            end
        end
    end,

    movetile = function(id, x, y)
        for key, package in pairs(br.packages) do
            local px = package.x
            local py = package.y

            if x >= px - 1 and y >= py - 1 and x <= px + 1 and y <= py + 1 then
                local item = package.config.items[math.random(1, #package.config.items)]
                parse('effect "colorsmoke" ' .. px * 32 + 16 .. ' ' .. py * 32 + 16 .. ' 4 16 '
                        .. table.concat(package.config.effectColor, ' '))
                parse('spawnitem ' .. item .. ' ' .. px .. ' ' .. py)
                freeimage(package.image)
                br.packages[key] = nil

                local text = string.char(169) .. '090090255Item(s) found: ' .. itemtype(item, 'name')
                local extraitem
                if math.random(1, 100) / 100 <= package.config.extraItemChance then
                    extraitem = package.config.items[math.random(1, #package.config.items)]
                    local countWalkable = 0
                    for nx = px - 1, px + 1 do
                        for ny = py - 1, py + 1 do
                            if tile(nx, ny, 'walkable') then
                                countWalkable = countWalkable + 1
                            end
                        end
                    end

                    local sx, sy = px, py
                    if countWalkable > 2 then
                        repeat
                            sx = math.random(-1, 1)
                            sy = math.random(-1, 1)
                        until not (sx == 0 and sy == 0) and tile(px + sx, py + sy, 'walkable')
                    end

                    parse('effect "colorsmoke" ' .. (px + sx) * 32 + 16 .. ' ' .. (py + sy) * 32 + 16 .. ' 4 16 '
                            .. table.concat(package.config.effectColor, ' '))
                    parse('spawnitem ' .. extraitem .. ' ' .. px + sx .. ' ' .. py + sy)
                    text = text .. ' and ' .. itemtype(extraitem, 'name')
                end
                msg2(id, text)
            end
        end

        if br.player[id].sprinting then
            parse('effect "colorsmoke" ' .. player(id, 'x') .. ' ' .. player(id, 'y') .. '  1 1 128 128 128')
        end
    end,

    hit = function(victim, source)
        if br.gracePeriodTimer > 0 then
            if source > 0 then
                msg2(source, string.char(169) .. '255000000You cannot deal damage during the grace period!@C')
            end

            return 1
        else
            br.funcs.timer.init(10, br.funcs.player.updateHud, victim)
        end
    end,

    buy = function()
        return 1
    end,

    spawn = function(id)
        if br.player[id].killed then
            parse('killplayer ' .. id)
        end
        br.funcs.player.updateHud(id)

        return 'x'
    end,

    serveraction = function(id, action)
        if action == 1 then
            local menuString, aura = 'Select aura', br.player[id].storedData.aura
            for k, v in pairs(br.config.auras) do
                if aura ~= k then
                    menuString = menuString .. ',' .. v[1]
                else
                    menuString = menuString .. ',(' .. v[1] .. ')'
                end
            end

            if aura ~= 0 then
                menuString = menuString .. ',No aura'
            else
                menuString = menuString .. ',(No aura)'
            end

            menu(id, menuString)
        elseif action == 2 then
            if player(id, 'health') > 0 then
                if br.player[id].ui.skins.opened then
                    parse('setweapon ' .. id .. ' '.. br.player[id].ui.skins.lastWep)
                else
                    br.player[id].ui.skins.lastWep = player(id, 'weapontype')
                    parse('setweapon ' .. id .. ' 50')
                end
            end

            br.player[id].ui.skins.opened = not br.player[id].ui.skins.opened
        end

        br.funcs.player.updateHud(id)
    end,

    menu = function(id, menu, button)
        if menu == 'Select aura' then
            if button >= 1 and button <= 8 then
                br.player[id].storedData.aura = button
                br.funcs.player.updateAura(id)
            elseif button == 9 then
                br.player[id].storedData.aura = 0
                br.funcs.player.updateAura(id)
            end
        end
    end,

    say = function(id, message)
        if message == 'rank' then return 0 end

        local role = br.config.roles[br.player[id].role]
        local c, r = string.char(169), '255000000'

        if (message:sub(1, 1) == '!') then
            local segments = br.funcs.string.split(message)
            for _, v in pairs(br.commands) do
                if segments[1]:sub(2) == v.command then
                    if not br.funcs.table.find(v.roles, br.player[id].role) then
                        msg2(id, c .. r .. 'You are not allowed to use this command.')
                        return 1
                    end

                    table.remove(segments, 1)
                    local success, emsg = pcall(v.func, id, role, segments)
                    if not success then
                        msg2(id, c .. r .. 'A Lua error occured during the execution of this command.')
                        print(c .. r .. emsg)
                    end

                    return 1
                end
            end

            msg2(id, c .. r .. 'Unknown command "' .. segments[1]:sub(2) .. '".')
        else
            --[[
            local g, y, sc, name, health, tag, message =
                '000255000',
                '255220000',
                string.format('%03d%03d%03d', unpack(role.color)),
                player(id, 'name'),
                player(id, 'health'),
                role.tag,
                ((message:sub(-2) == '@C' and not role.allowAtC) and message:sub(1, -3) or message)
            local newMsg = c .. g .. name .. (tag and c .. sc .. ' [' .. tag .. ']' or '')
                .. (health <= 0 and c .. y .. ' *DEAD*: ' or ': ') .. c .. sc .. message
            if player(id, 'team') == 0 then
                for _, pl in pairs(player(0, 'table')) do
                    if player(pl, 'health') <= 0 then
                        msg2(pl, newMsg)
                    end
                end
            else
                msg(newMsg)
            end]]
            return 0
        end

        return 1
    end,

    projectile = function(id, weapon, x, y)
        if weapon == 86 then
            parse('spawnnpc 3 ' .. (x / 32) .. ' ' .. (y / 32) .. ' 0')
            return 1
        end
    end,

    walkover = function(id, iid, type, ain, a, mode)
        if (type >= 64 and type <= 65) or (type >= 57 and type <= 58) or (type >= 79 and type <= 84) then
            br.funcs.timer.init(10, br.funcs.player.updateHud, id)
        end
    end,

    key = function(id, key, state)
        if key == 'space' then
            if state == 1 then
                if br.player[id].stamina > 0 then
                    br.player[id].sprinting = true
                    parse('speedmod ' .. id .. ' 13')
                end
            else
                br.player[id].sprinting = false
                parse('speedmod ' .. id .. ' 0')
            end
        elseif key == 'escape' and state == 0 then
            if br.player[id].ui.skins.opened then
                br.player[id].ui.skins.opened = false
                br.funcs.player.updateHud(id)
            end
        elseif key == 'mouse1' then
            if not br.player[id].ui.skins.opened then return end
            local hover = br.player[id].ui.skins.hover
            if hover == 'none' then return end

            if hover:sub(1, 3) == 'cat' then
                br.player[id].ui.skins.cat = tonumber(hover:sub(4))
                br.funcs.player.updateHud(id)
            elseif hover == 'exit' then
                br.player[id].ui.skins.opened = false
                br.funcs.player.updateHud(id)
            end
        end
    end,

    move = function(id, x, y, walk)
        if br.player[id].sprinting and walk == 0 then
            br.player[id].stamina = br.player[id].stamina - 0.33
            if br.player[id].stamina < 0 then
                br.player[id].stamina = 0
                br.player[id].sprinting = false
                parse('speedmod ' .. id .. ' 0')
            else
                parse('speedmod ' .. id .. ' 13')
            end
            br.funcs.player.updateHud(id)
        elseif br.player[id].sprinting and walk == 1 then
            parse('speedmod ' .. id .. ' 0')
        end
    end,

    clientdata = function(id, mode, data1, data2)
        local x, y, skinsConf = data1, data2, br.config.ui.skins

        br.player[id].ui.skins.hover = 'none'
        if x >= skinsConf.exit.box[1] and y >= skinsConf.exit.box[2]
            and x <= skinsConf.exit.box[3] and y <= skinsConf.exit.box[4] then
            br.player[id].ui.skins.hover = 'exit'
        end

        for k, v in pairs(skinsConf.categories) do
            if x >= v.box[1] and y >= v.box[2] and x <= v.box[3] and y <= v.box[4] then
                br.player[id].ui.skins.hover = 'cat' .. k
            end
        end

        for ty = 1, skinsConf.slots.dimensions[2] do
            for tx = 1, skinsConf.slots.dimensions[1] do
                local fx1, fy1 = skinsConf.slots.firstBox[1], skinsConf.slots.firstBox[2]
                local fx2, fy2 = skinsConf.slots.firstBox[3], skinsConf.slots.firstBox[4]
                local ox, oy   = skinsConf.slots.offset[1], skinsConf.slots.offset[2]

                local x1, y1 = fx1 + (fx2 - fx1 + ox) * (tx - 1), fy1 + (fy2 - fy1 + oy) * (ty - 1)
                local x2, y2 = x1 + (fx2 - fx1), y1 + (fy2 - fy1)
                if x >= x1 and y >= y1 and x <= x2 and y <= y2 then
                    br.player[id].ui.skins.hover = 'slot_' .. string.format('%03d_%03d', tx, ty)
                end
            end
        end

        if x >= skinsConf.directionals.prev[1] and y >= skinsConf.directionals.prev[2]
            and x <= skinsConf.directionals.prev[3] and y <= skinsConf.directionals.prev[4] then
            br.player[id].ui.skins.hover = 'prev'
        elseif x >= skinsConf.directionals.next[1] and y >= skinsConf.directionals.next[2]
            and x <= skinsConf.directionals.next[3] and y <= skinsConf.directionals.next[4] then
            br.player[id].ui.skins.hover = 'next'
        end

        br.funcs.player.updateHud(id)
    end
}
