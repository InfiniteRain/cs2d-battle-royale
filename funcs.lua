return 

{
    geometry = {
        distance = function(x1, y1, x2, y2)
            return math.sqrt((y1 - y2)^2 + (x1 - x2)^2)
        end,

        getAngle = function(x1, y1, x2, y2)
            return -math.deg(math.atan2(x1 - x2, y1 - y2))
        end,

        extendPosition = function(x, y, dir, dist)
            return x + math.sin(math.rad(dir)) * dist, y - math.cos(math.rad(dir)) * dist
        end,

        drawLine = function(x1, y1, x2, y2, mode, alpha, color)
            local mode = mode or 1
            local alpha = alpha or 1
            local color = color or {255, 255, 255}

            local line = image('gfx/block.bmp', 0, 0, mode)
            local angle, distance = 
                    br.funcs.geometry.getAngle(x1, y1, x2, y2), 
                    br.funcs.geometry.distance(x1, y1, x2, y2)
            local x, y = br.funcs.geometry.extendPosition(x1, y1, angle, distance / 2)
            imagepos(line, x, y, angle)
            imagescale(line, 1, distance / 32)
            imagealpha(line, alpha)
            imagecolor(line, unpack(color))
            return {
                image = line, 
                x1 = x1, 
                y1 = y1, 
                x2 = x2, 
                y2 = y2
            }
        end,

        moveLine = function(line, x1, y1, x2, y2, ms)
            local ms = ms or 0

            line.x1 = x1
            line.y1 = y1
            line.x2 = x2
            line.y2 = y2
            local angle, distance = 
                    br.funcs.geometry.getAngle(x1, y1, x2, y2), 
                    br.funcs.geometry.distance(x1, y1, x2, y2)
            local x, y = br.funcs.geometry.extendPosition(x1, y1, angle, distance / 2)

            if ms >= 0 then
                tween_move(line.image, ms, x, y, angle)
                tween_scale(line.image, ms, 1, distance / 32)
            else
                imagepos(line.image, x, y, angle)
                imagescale(line.image, 1, distance / 32)
            end
        end,

        freeLine = function(line)
            freeimage(line.image)
        end,

        drawCircle = function(x, y, radius, pointsCount, mode, alpha, color)
            local points = {}
            local i = 1
            for dir = -180, 180, 360 / pointsCount do
                points[i] = {br.funcs.geometry.extendPosition(x, y, dir, radius)}
                i = i + 1
            end
            
            local circle = {
                x = x,
                y = y,
                radius = radius,
                pointsCount = pointsCount,
                points = points,
                lines = {}
            }

            for i = 1, pointsCount do
                local nextPoint = (i == pointsCount and 1 or i + 1)
                local line = br.funcs.geometry.drawLine(
                    points[i][1],
                    points[i][2],
                    points[nextPoint][1],
                    points[nextPoint][2],
                    mode,
                    alpha,
                    color
                )
                
                circle.lines[i .. '-' .. nextPoint] = line
            end
            
            return circle
        end,

        changeCircleRadius = function(circle, radius, ms)
            local ms = ms or 0

            circle.radius = radius
            local i = 1
            for dir = -180, 180, 360 / circle.pointsCount do
                circle.points[i] = {br.funcs.geometry.extendPosition(circle.x, circle.y, dir, radius)}
                i = i + 1
            end

            for i = 1, circle.pointsCount do
                local nextPoint = (i == circle.pointsCount and 1 or i + 1)
                br.funcs.geometry.moveLine(
                    circle.lines[i .. '-' .. nextPoint],
                    circle.points[i][1],
                    circle.points[i][2],
                    circle.points[nextPoint][1],
                    circle.points[nextPoint][2],
                    ms
                )
            end
        end,

        freeCircle = function(circle)
            for _, v in pairs(circle.lines) do
                br.funcs.geometry.freeLine(v)
            end
        end
    },

    game = {
        checkIfSpawnable = function(x, y)
            if not tile(x, y, 'walkable') or tile(x, y, 'frame') == 0 then
                return false
            end
            
            for pattern, conf in pairs(br.config.unspawnableZones) do
                if map('name'):match(pattern) then
                    for _, v in pairs(conf) do
                        if x >= v[1] and y >= v[2] and x <= v[3] and y <= v[4] then
                            return false
                        end
                    end
                end

                break
            end

            for _, v in pairs(br.packages) do
                if v.x == x and v.y == y then
                    return false
                end
            end

            return true
        end,

        checkIfEnded = function()
            if not br.roundEnded then
                local alivePlayers, lastAlivePlayerName, lastAlivePlayerId = 0, '', 0
                for _, pl in pairs(player(0, 'table')) do
                    if br.player[pl].inGame and not br.player[pl].killed then
                        alivePlayers = alivePlayers + 1
                        lastAlivePlayerName = player(pl, 'name')
						lastAlivePlayerId = pl
                    end
                end		

                if alivePlayers <= 1 then
                    local text
                    if alivePlayers == 1 then
                        text = string.char(169) .. '000255000' .. lastAlivePlayerName .. ' has WON the game!@C'
						br.funcs.player.addExp(lastAlivePlayerId, 350)
                    elseif alivePlayers == 0 then
                        text = 'The game has ended in a DRAW!@C'
                    end
                    
                    br.roundEnded = true

                    msg(text)
                    parse('restart 5')
                end
            end
        end,

        updateGlobalHudTexts = function()
            local graceText
            if br.gracePeriodTimer == 0 then
                graceText = string.char(169) .. '255000000The grace period is over!'
            else
                graceText = string.char(169) .. '255255000Seconds left until the end of the grace period: ' 
                        .. br.gracePeriodTimer
            end
            parse('hudtxt 1 "' .. graceText .. '" 415 65 1')

            local alivePlayers = 0
            local deadPlayers  = 0
            local specPlayers  = 0
            for _, pl in pairs(player(0, 'table')) do
                if br.player[pl].inGame and not br.player[pl].killed then
                    alivePlayers = alivePlayers + 1
                elseif br.player[pl].inGame and br.player[pl].killed then	
                    deadPlayers = deadPlayers + 1
                else
                    specPlayers = specPlayers + 1
                end
            end

            local text = 
                    string.char(169) .. '000255000Alive: ' .. alivePlayers .. ' | ' .. 
                    string.char(169) .. '255000000Dead: '  .. deadPlayers  .. ' | ' ..
                    string.char(169) .. '255255255Spec: '  .. specPlayers
            parse('hudtxt 2 "' .. text .. '" 415 50 1')
        end
    },

    player = {
        updatePlayerHudTexts = function(id)
            local levelText
            local levelData = br.funcs.player.getExpData(id)
            
            levelText = string.char('169') .. '030144255Exp.: ' .. levelData.currentExp .. ' | Level: ' 
                .. levelData.currentLevel .. ' | Next level: ' .. levelData.progressNextLevel .. '/' 
                .. levelData.neededForNextLevel
            parse('hudtxt2 ' .. id ..' 3 "'.. levelText .. '" 415 430 1')

            if player(id, 'steamid') == '0' then
                local warnText = string.char(169) .. '255000000You\'re not logged into Steam! Your level progress will '
                        .. 'NOT be saved!'
                parse('hudtxt2 ' .. id .. ' 4 "' .. warnText .. '" 415 415 1')
            end
			
			local killedText = ''
			if br.player[id].inGame and br.player[id].killed then
				killedText = string.char(169) .. '255000000You\'re DEAD. If you try to respawn, you will get '
                        .. 'instantly killed!'
			end
			parse('hudtxt2 ' .. id ..' 0 "' .. killedText .. '" 415 35 1')
        end,

        getExpData = function(id)
            local sd = br.player[id].storedData
            local currentExp = sd.exp
            local currentLevel = math.floor((sd.exp + 1) ^ (1 / 2.5))
            local nextLevelExp = math.floor((currentLevel + 1) ^ 2.5)
            local thisLevelExp = math.floor(currentLevel ^ 2.5) - 1
            local neededForNextLevel = nextLevelExp - thisLevelExp
            local progressNextLevel = currentExp - thisLevelExp

            return {
                currentExp = currentExp,
                currentLevel = currentLevel,
                nextLevelExp = nextLevelExp,
                thisLevelExp = thisLevelExp,
                neededForNextLevel = neededForNextLevel,
                progressNextLevel = progressNextLevel
            }
        end,

        getExpWorth = function(id)
            local worth = 0
            for _, v in pairs(playerweapons(id)) do
                if v == 79 or v == 84 or v == 41 then
                    worth = worth + 30
                elseif v == 80 then
                    worth = worth + 60
                elseif v == 69 or v == 78 then
                    worth = worth + 20
                else
                    worth = worth + itemtype(v, 'dmg')
                end
            end

            worth = worth * 1.2
            if worth < 50 then worth = 50 end
            if worth > 200 then worth = 200 end
            return math.floor(worth)
        end,

        addExp = function(id, exp)
            local sd = br.player[id].storedData
            local oldExpData = br.funcs.player.getExpData(id)
            sd.exp = sd.exp + exp
            local newExpData = br.funcs.player.getExpData(id)

            if oldExpData.currentLevel < newExpData.currentLevel then
                local currentLevel = newExpData.currentLevel
                local advancedLevels = currentLevel - oldExpData.currentLevel
                msg(
                    string.char(169) .. '000255000' .. player(id, 'name') .. ' had advanced ' .. advancedLevels 
                            .. ' level(s)! They are now level ' .. currentLevel ..'!'
                )

                local x, y, health = player(id, 'x'), player(id, 'y'), player(id, 'health')
                if health > 0 then
                    parse('effect "flare" ' .. x ..' ' .. y .. ' 64 64 255 127 0')
                end
            end

            br.funcs.player.updatePlayerHudTexts(id)
        end,

        getStandardPlayerData = function()
            return {
                killed           = true,
                inGame           = false,
                auraImage        = false,
                storedData       = {},
                loadedStoredData = false
            }
        end,

        loadStoredData = function(id)
            local steamid = player(id, 'steamid')
            
            br.player[id].storedData = br.funcs.table.copy(br.config.playerStoredDataSchema)
            if steamid ~= '0' then
                local success, loader = pcall(loadfile, 'sys/lua/battle_royale/storage/' .. steamid .. '.lua')
                if success and loader ~= nil then
                    local data = loader()
                    for k, v in pairs(data) do
                        br.player[id].storedData[k] = v
                    end
                end
            end

            br.player[id].loadedStoredData = true
        end,

        saveStoredData = function(id)
            if br.player[id] and not br.player[id].loadedStoredData then return end

            local steamid = player(id, 'steamid')

            if steamid ~= '0' then
                local file = io.open('sys/lua/battle_royale/storage/' .. steamid .. '.lua', 'w')
                file:write('return ' .. br.funcs.table.toString(br.player[id].storedData))
                file:close() 
            end
        end,
    },

    table = {
        toString = function(tbl)
            local str = '{'
            for k, v in pairs(tbl) do
                if type(v) == 'function' or type(v) == 'userdata' or type(v) == 'thread' then
                    error('variables of type "' .. type(v) .. '" cannot be turned into a string', 2)
                elseif type(k) == 'function' or type(k) == 'userdata' or type(k) == 'thread' or type(k) == 'table' then
                    error('variables of type "' .. type(k) .. '" cannot be used as keys in a stringified table', 2)
                elseif type(v) == 'table' then
                    local success, entry = pcall(br.funcs.table.toString, v)
                    if success then
                        str = str .. k .. '=' .. entry .. ','
                    else
                        error(entry, 2)
                    end
                elseif type(v) == 'string' then
                    local entry = v:gsub('([\\"])', '\\%1')
                    str = str .. k .. '="' .. entry ..'",' 
                else
                    str = str .. k .. '=' .. tostring(v) .. ','
                end
            end

            return str .. '}'
        end,

        copy = function(tbl)
            local copy = {}
            for k, v in pairs(tbl) do
                if type(v) == 'table' then
                    local entry = br.funcs.table.copy(v)
                    copy[k] = entry
                else
                    copy[k] = v
                end
            end

            return copy
        end
    }
}
