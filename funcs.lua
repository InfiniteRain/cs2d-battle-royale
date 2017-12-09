return 

{
    timer = {
        init = function(time, func, ...)
            local args = {...}
            _G['TIMERS'] = _G['TIMERS'] or {}

            local i, name = 0, ''
            repeat
                name = 't' .. i
                i = i + 1
            until _G['TIMERS'][name] == nil

            _G['TIMERS'][name] = {
                name = name,
                func = function()
                    func(unpack(args))
                    _G['TIMERS'][name] = nil
                end
            }

            timer(time, 'TIMERS.' .. name ..'.func')
            return _G['TIMERS'][name]
        end,

        free = function(timer)
            freetimer('TIMERS.' .. timer.name .. '.func')
            _G['TIMERS'][timer.name] = nil
        end
    },

    train = {
        launch = function(train)
            if train.running then error('this train is already running', 2) end

            local distance = br.funcs.geometry.distance(
                train.realStart[1], train.realStart[2], 
                train.realFinish[1], train.realFinish[2]
            )
            local time = distance / train.config.speed * 1000
            imagealpha(train.image, 1)
            imagepos(train.image, train.realStart[1], train.realStart[2], train.angle)
            tween_move(train.image, time, train.realFinish[1], train.realFinish[2])

            train.running = true
            train.startedAt = os.clock() * 1000
            train.finishesIn = time

            br.funcs.timer.init(time, function() 
                imagealpha(train.image, 0)

                train.running = false
                train.startedAt = 0
                train.finishesIn = 0

                br.funcs.timer.init(train.config.cycle * 1000, br.funcs.train.launch, train)
            end)
        end,

        positionInTrain = function(train, cx, cy)
            if not train.running then return false end
            
            local x, y, points = object(train.image, 'x'), object(train.image, 'y'), {}
            local points = {}

            for my = -1, 1, 2 do
                for mx = -1, 1, 2 do
                    if mx == 1 and my == 1 then break end
                    local fx, fy = br.funcs.geometry.extendPosition(
                        x, y, train.angle + (-90 * mx), train.config.size[1] / 2
                    )
                    table.insert(points, {br.funcs.geometry.extendPosition(
                        fx, fy, train.angle, my * train.config.size[2] / 2
                    )})
                end
            end

            local ax = points[1][1]
            local ay = points[1][2]
            local bx = points[2][1]
            local by = points[2][2]
            local dx = points[3][1]
            local dy = points[3][2]

            local bax = bx - ax
            local bay = by - ay
            local dax = dx - ax
            local day = dy - ay

            if ((cx - ax) * bax + (cy - ay) * bay < 0.0) then return false end
            if ((cx - bx) * bax + (cy - by) * bay > 0.0) then return false end
            if ((cx - ax) * dax + (cy - ay) * day < 0.0) then return false end
            if ((cx - dx) * dax + (cy - dy) * day > 0.0) then return false end
            
            return true
        end
    },

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

        drawLine = function(x1, y1, x2, y2, width, mode, alpha, color)
            local mode = mode or 1
            local alpha = alpha or 1
            local color = color or {255, 255, 255}

            local line = image('gfx/block.bmp', 0, 0, mode)
            local angle, distance = 
                    br.funcs.geometry.getAngle(x1, y1, x2, y2), 
                    br.funcs.geometry.distance(x1, y1, x2, y2)
            local x, y = br.funcs.geometry.extendPosition(x1, y1, angle, distance / 2)
            imagepos(line, x, y, angle)
            imagescale(line, (1 / 32) * width, distance / 32)
            imagealpha(line, alpha)
            imagecolor(line, unpack(color))
            return {
                image = line, 
                x1 = x1, 
                y1 = y1, 
                x2 = x2, 
                y2 = y2,
                width = width
            }
        end,

        moveLine = function(line, x1, y1, x2, y2)
            line.x1 = x1
            line.y1 = y1
            line.x2 = x2
            line.y2 = y2
            local angle, distance = 
                    br.funcs.geometry.getAngle(x1, y1, x2, y2), 
                    br.funcs.geometry.distance(x1, y1, x2, y2)
            local x, y = br.funcs.geometry.extendPosition(x1, y1, angle, distance / 2)

            imagepos(line.image, x, y, angle)
            imagescale(line.image, (1 / 32) * line.width, distance / 32)
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
        end,

        drawZone = function(x, y, radius, alpha)
            local img = image(br.config.dangerZoneImage, x, y, 3)
            imagescale(img, radius / 307, radius / 307)

            return {
                x = x,
                y = y,
                radius = radius,
                shrinking = false,
                shrinkStart = 0,
                shrinkEnd = 0,
                shrinkFinalRadius = 0,
                timer = false,
                image = img
            }
        end,

        getZoneRadius = function(zone)
            if zone.shrinking then
                local starting, finishing = zone.radius, zone.shrinkFinalRadius
                local timerStarted, timerNeeded = zone.shrinkStart, zone.shrinkEnd
                local multiplier = ((os.clock() * 1000) - timerStarted) / timerNeeded
                return starting + (finishing - starting) * multiplier
            else
                return zone.radius
            end
        end,

        shrinkZone = function(zone, radius, speed)
            local finalScale   = radius / 307
            local currentScale = zone.radius / 307
            local millisecs = (zone.radius - radius) / speed * 1000
            tween_scale(zone.image, millisecs, finalScale, finalScale)

            zone.shrinking = true
            zone.shrinkStart = os.clock() * 1000
            zone.shrinkEnd = millisecs
            zone.shrinkFinalRadius = radius
            zone.timer = br.funcs.timer.init(millisecs, function() 
                zone.shrinking = false
                zone.shrinkStart = 0
                zone.shrinkEnd = 0
                zone.radius = zone.shrinkFinalRadius
                zone.shrinkFinalRadius = 0
                zone.timer = false
            end)
        end,
    },

    game = {
        checkIfSpawnable = function(x, y)
            if not tile(x, y, 'walkable') or tile(x, y, 'frame') == 0 then
                return false
            end
            
            for pattern, conf in pairs(br.config.maps) do
                if map('name'):match(pattern) then
                    for _, v in pairs(conf.unspawnableZones) do
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
                        text = lastAlivePlayerName .. ' has WON the game!'
                        br.funcs.player.addExp(lastAlivePlayerId, 450)
                        
                        for i = 1, 5 do
                            msg(
                                string.char(169) .. 
                                math.random(100, 255) ..
                                math.random(100, 255) ..
                                math.random(100, 255) ..
                                text ..
                                string.rep(' ', i) ..
                                '@C'
                            )
                        end
                    elseif alivePlayers == 0 then
                        text = 'The game has ended in a DRAW!@C'
                        msg(text)
                    end
                    
                    br.roundEnded = true
                    parse('trigger draw')
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
        updateHud = function(id)
            local expText, levelText
            local levelData = br.funcs.player.getExpData(id)    
            expText = string.char('169') .. '255165000' .. levelData.progressNextLevel .. '/' 
                .. levelData.neededForNextLevel
            parse('hudtxt2 ' .. id ..' 3 "'.. expText .. '" 428 422 1')
            levelText = string.char('169') .. '030144255' .. levelData.currentLevel
            parse('hudtxt2 ' .. id ..' 5 "'.. levelText .. '" 347 422 1')


            if player(id, 'steamid') == '0' then
                local warnText = string.char(169) .. '255000000You\'re not logged into Steam! Your level progress will '
                        .. 'NOT be saved!'
                parse('hudtxt2 ' .. id .. ' 4 "' .. warnText .. '" 415 415 1')
            end
            
            local killedText = ''
            if br.player[id].inGame and br.player[id].killed then
                killedText = string.char(169) .. '255000000You\'re DEAD. If you try to respawn, you will get instantly '
                        .. 'killed!'
            end
            parse('hudtxt2 ' .. id ..' 0 "' .. killedText .. '" 415 35 1')

            if not br.player[id].xpBar then
                br.player[id].xpBar = br.funcs.geometry.drawLine(0, 0, 0, 0, 12, 2, 0.5, {30, 144, 255})
            end

            local barWidth = 128 * (levelData.progressNextLevel / levelData.neededForNextLevel)
            br.funcs.geometry.moveLine(br.player[id].xpBar, 364, 430, 364 + barWidth, 430)
        end,

        getExpData = function(id)
            local sd = br.player[id].storedData
            local currentExp = sd.exp
            local currentLevel = math.floor(math.sqrt((sd.exp + 1) / 150))
            local nextLevelExp = math.floor(((currentLevel + 1) ^ 2) * 150)
            local thisLevelExp = math.floor((currentLevel ^ 2) * 150)
            local neededForNextLevel = nextLevelExp - thisLevelExp
            local progressNextLevel = currentExp - thisLevelExp

            return {
                currentExp = currentExp,
                currentLevel = currentLevel + 1,
                nextLevelExp = nextLevelExp,
                thisLevelExp = thisLevelExp,
                neededForNextLevel = neededForNextLevel,
                progressNextLevel = (currentLevel == 0 and progressNextLevel or progressNextLevel + 1)
            }
        end,

        addExp = function(id, exp)
            local sd = br.player[id].storedData
            local oldExpData = br.funcs.player.getExpData(id)
            sd.exp = sd.exp + exp
            local newExpData = br.funcs.player.getExpData(id)

            if oldExpData.currentLevel < newExpData.currentLevel then
                local currentLevel = newExpData.currentLevel
                msg(
                    string.char(169) .. '000255000' .. player(id, 'name') .. ' had advanced to level ' 
                    .. currentLevel ..'!'
                )

                local x, y, health = player(id, 'x'), player(id, 'y'), player(id, 'health')
                if health > 0 then
                    parse('effect "flare" ' .. x ..' ' .. y .. ' 64 64 255 127 0')
                end
            end

            br.funcs.player.updateHud(id)
        end,

        updateAura = function(id)
            if br.player[id].auraImage then
                freeimage(br.player[id].auraImage)
                br.player[id].auraImage = false
            end

            if br.player[id].storedData.aura > 0 then
                local aura = br.config.auras[br.player[id].storedData.aura]
                br.player[id].auraImage = image(br.config.auraImage, 0, 0, 100 + id)
                imageblend(br.player[id].auraImage, 1)
                imagecolor(br.player[id].auraImage, aura[2], aura[3], aura[4])
                imagealpha(br.player[id].auraImage, 0.6)
            end
        end,

        getDataSchema = function()
            return {
                killed           = true,
                inGame           = false,
                auraImage        = false,
                storedData       = {},
                loadedStoredData = false,
                role             = 'player',
                xpBar            = false
            }
        end,

        getStoredDataSchema = function()
            return {
                exp  = 0,
                aura = 0
            }
        end,

        loadStoredData = function(id)
            local steamid = player(id, 'steamid')
            
            br.player[id].storedData = br.funcs.player.getStoredDataSchema()
            if steamid ~= '0' then
                local file = io.open('sys/lua/battle_royale/storage/' .. steamid .. '.lua', 'rb')
                if file then
                    local data = assert(loadstring(file:read('*all')))()
                    for k, v in pairs(data) do
                        br.player[id].storedData[k] = v
                    end

                    file:close()
                end
            end

            br.player[id].loadedStoredData = true
        end,

        saveStoredData = function(id)
            if not br.player[id] or not br.player[id].loadedStoredData then return end

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
                end

                local key = (type(k) == 'string' and '["' .. k:gsub('([\\"])', '\\%1') .. '"]' or k)
                if type(v) == 'table' then
                    local success, entry = pcall(br.funcs.table.toString, v)
                    if success then
                        str = str .. key .. '=' .. entry .. ','
                    else
                        error(entry, 2)
                    end
                elseif type(v) == 'string' then
                    str = str .. key .. '="' .. v:gsub('([\\"])', '\\%1') ..'",' 
                else
                    str = str .. key .. '=' .. tostring(v) .. ','
                end
            end

            return str .. '}'
        end,

        find = function(tbl, elem) 
            for _, v in pairs(tbl) do
                if v == elem then
                    return true
                end
            end

            return false
        end,
    },

    string = {
        trim = function(str)
            return str:match('^%s*(.-)%s*$')
        end,

        split = function(str, delim)
            local words = {}
            for word in str:gmatch(delim or '%S+') do
                table.insert(words, word)
            end
            return words
        end
    },

    server = {
        checkServertransfer = function()
            local file = assert(
                io.open('sys/servertransfer.lst', 'r'),
                'failed to open \'servertransfer.lst\' file for reading'
            )
            local checkList = {}
            for _, v in pairs(br.config.servertransfer) do
                checkList[v] = false
            end

            for line in file:lines() do
                local trimmed = br.funcs.string.trim(line)
                if checkList[trimmed] ~= nil then
                    checkList[trimmed] = true
                end
            end

            file:close()
            file = assert(
                io.open('sys/servertransfer.lst', 'a'),
                'failed to open \'servertransfer.lst\' file for appending'
            )

            local changed = false
            for k, v in pairs(checkList) do
                if not v then
                    changed = true
                    file:write(br.funcs.string.trim(k), '\n')
                end
            end

            file:close()

            if changed then
                parse('changemap ' .. map 'name')
            end
        end
    }
}
