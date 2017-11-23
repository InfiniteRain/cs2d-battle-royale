return 

{
    join = function(id)
        br.player[id] = br.funcs.player.getStandardPlayerData()
        br.funcs.player.loadStoredData(id)
        br.funcs.player.updatePlayerHudTexts(id)
        br.funcs.game.updateGlobalHudTexts()

        if br.player[id].storedData.aura > 0 then
            local aura = br.config.auras[br.player[id].storedData.aura]
            br.player[id].auraImage = image(br.config.auraImage, 0, 0, 100 + id)
            imageblend(br.player[id].auraImage, 1)
            imagecolor(br.player[id].auraImage, aura[2], aura[3], aura[4])
        end
    end,

    leave = function(id)
        br.funcs.player.saveStoredData(id)
        br.player[id] = br.funcs.player.getStandardPlayerData()
        br.funcs.game.updateGlobalHudTexts()
        br.funcs.game.checkIfEnded()
    end,

    team = function(id, team)
        if player(id, 'team') == 0 and team > 0 then
            br.player[id].inGame = true
            br.player[id].killed = true
            br.funcs.player.updatePlayerHudTexts(id)

            local activePlayers = 0
            for _, pl in pairs(player(0, 'table')) do
                if br.player[pl].inGame then
                    activePlayers = activePlayers + 1
                end
            end

            if activePlayers <= 2 then
                parse('restart')
            end
        elseif player(id, 'team') > 0 and team == 0 then
            br.player[id].inGame = false
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

        for _, pl in pairs(player(0, 'table')) do
            if br.player[pl].inGame then
                br.player[pl].killed = false

                local spawnx, spawny
                repeat
                    spawnx = math.random(0, map 'xsize')
                    spawny = math.random(0, map 'ysize')
                until br.funcs.game.checkIfSpawnable(spawnx, spawny)

                parse('spawnplayer ' .. pl .. ' ' .. spawnx * 32 + 16 .. ' ' .. spawny * 32 + 16)
                br.funcs.player.updatePlayerHudTexts(pl)
                
                if br.player[pl].storedData.aura > 0 then
                    local aura = br.config.auras[br.player[pl].storedData.aura]
                    br.player[pl].auraImage = image(br.config.auraImage, 0, 0, 100 + pl)
                    imageblend(br.player[pl].auraImage, 1)
                    imagecolor(br.player[pl].auraImage, aura[2], aura[3], aura[4])
                end
            end
        end

        br.funcs.game.updateGlobalHudTexts()
    end,

    die = function(victim, killer)
        br.player[victim].killed = true
        if killer > 0 and killer ~= victim then
            br.funcs.player.addExp(killer, 150)
            br.funcs.player.updatePlayerHudTexts(killer)
        end

        parse('sv_sound "' .. br.config.killSoundFile .. '"')
        br.funcs.player.updatePlayerHudTexts(victim)
        br.funcs.game.checkIfEnded()
        br.funcs.game.updateGlobalHudTexts()
    end,

    second = function()
        br.gracePeriodTimer = br.gracePeriodTimer - 1
        if br.gracePeriodTimer <= 0 then
            br.gracePeriodTimer = 0
        end
        br.funcs.game.updateGlobalHudTexts()

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
        end
        
        if br.gracePeriodTimer > 0 then return end
        
        if not br.shrinkStarted and br.safeZone then
            br.shrinkStarted = true
            br.funcs.geometry.shrinkZone(br.safeZone, br.config.finalAreaRadius * 32, br.config.areaShrinkingSpeed)
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
    end,

    hit = function(victim, source)
        if br.gracePeriodTimer > 0 then
            msg2(source, string.char(169) .. '255000000You cannot deal damage during the grace period!@C')
            return 1
        end
    end,

    buy = function()
        return 1
    end,

    spawn = function(id)
        if br.player[id].killed then
            parse('killplayer ' .. id)
        end

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
        end
    end,

    menu = function(id, menu, button)
        if menu == 'Select aura' then
            if button ~= 0 then
                if br.player[id].auraImage ~= false then
                    freeimage(br.player[id].auraImage)
                end
            end

            if button >= 1 and button <= 8 then
                br.player[id].storedData.aura = button
                local aura = br.config.auras[button]
                br.player[id].auraImage = image(br.config.auraImage, 0, 0, 100 + id)
                imageblend(br.player[id].auraImage, 1)
                imagecolor(br.player[id].auraImage, aura[2], aura[3], aura[4])
            elseif button == 9 then
                br.player[id].storedData.aura = 0
                br.player[id].auraImage = false
            end
        end
    end
}
