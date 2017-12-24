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

    hudtext = {
        new = function(pl, hid, text, x, y, align, valign, size)
            align = align or 0
            valign = valign or 0
            size = size or 13

            parse(
                'hudtxt2 ' .. pl .. ' ' .. hid .. ' "' .. text .. '" ' .. x .. ' ' .. y .. ' '
                    .. align .. ' ' .. valign .. ' ' .. size
            )

            return {
                pl = pl,
                hid = hid,
                text = text,
                x = x,
                y = y,
                align = align,
                valign = valign,
                size = size,
                alpha = 1,

                setText = br.funcs.hudtext.setText,
                setAlpha = br.funcs.hudtext.setAlpha
            }
        end,

        setText = function(h, text)
            if h.text == text then return end

            h.text = text
            parse(
                'hudtxt2 ' .. h.pl .. ' ' .. h.hid .. ' "' .. h.text .. '" ' .. h.x .. ' ' .. h.y .. ' '
                    .. h.align .. ' ' .. h.valign .. ' ' .. h.size
            )
            parse(
                'hudtxtalphafade ' .. h.pl .. ' ' .. h.hid .. ' 1 ' .. h.alpha
            )
        end,

        setAlpha = function(h, alpha)
            if h.alpha == alpha then return end

            h.alpha = alpha
            parse(
                'hudtxtalphafade ' .. h.pl .. ' ' .. h.hid .. ' 0  ' .. h.alpha
            )
        end
    },

    train = {
        launch = function(train)
            if train.running then return end

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

        drawLine = function(x1, y1, x2, y2, width, mode, alpha, color, id)
            local mode = mode or 1
            local alpha = alpha or 1
            local color = color or {255, 255, 255}

            local line = image('gfx/block.bmp', 0, 0, mode, id)
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
                color = color,
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

        colorLine = function(line, color)
            if color[1] == line.color[1] and color[2] == line.color[2] and color[3] == line.color[3] then
                return
            end

            line.color = color
            imagecolor(line.image, color[1], color[2], color[3])
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

        getZoneRadiusAtTimePoint = function(zone, point)
            if zone.shrinking then
                local starting, finishing = zone.radius, zone.shrinkFinalRadius
                local timerStarted, timerNeeded = zone.shrinkStart, zone.shrinkEnd
                local multiplier = (point - timerStarted) / timerNeeded
                return starting + (finishing - starting) * multiplier
            else
                return zone.radius
            end
        end,

        getZoneRadius = function(zone)
            return br.funcs.geometry.getZoneRadiusAtTimePoint(zone, os.clock() * 1000)
        end,

        shrinkZone = function(zone, radius, speed)
            local finalScale   = radius / 307
            local currentScale = zone.radius / 307
            local millisecs = (zone.radius - radius) / speed * 1000

            zone.shrinking = true
            zone.shrinkStart = os.clock() * 1000
            zone.shrinkEnd = millisecs
            zone.shrinkFinalRadius = radius

            local initTweenScale
            initTweenScale = function(time)
                if time > 30000 then
                    local tempScale = br.funcs.geometry.getZoneRadiusAtTimePoint(zone, os.clock() * 1000 + 30000) / 307
                    tween_scale(zone.image, 30000, tempScale, tempScale)
                    br.funcs.timer.init(30000, initTweenScale, time - 30000)
                else
                    tween_scale(zone.image, time, finalScale, finalScale)
                end
            end
            initTweenScale(millisecs, initTweenScale)

            zone.timer = br.funcs.timer.init(millisecs, function()
                zone.shrinking = false
                zone.shrinkStart = 0
                zone.shrinkEnd = 0
                zone.radius = zone.shrinkFinalRadius
                zone.shrinkFinalRadius = 0
                zone.timer = false
            end)
        end,

        drawSquare = function(x1, y1, x2, y2, width, mode, alpha, color, id)
            local l1 = br.funcs.geometry.drawLine(x1, y1, x2, y1, width, mode, alpha, color, id)
            local l2 = br.funcs.geometry.drawLine(x2, y1, x2, y2, width, mode, alpha, color, id)
            local l3 = br.funcs.geometry.drawLine(x2, y2, x1, y2, width, mode, alpha, color, id)
            local l4 = br.funcs.geometry.drawLine(x1, y2, x1, y1, width, mode, alpha, color, id)

            return {
                l1 = l1,
                l2 = l2,
                l3 = l3,
                l4 = l4
            }
        end,

        freeSquare = function(sq)
            br.funcs.geometry.freeLine(sq.l1)
            br.funcs.geometry.freeLine(sq.l2)
            br.funcs.geometry.freeLine(sq.l3)
            br.funcs.geometry.freeLine(sq.l4)
        end
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
        end
    },

    player = {
        randomSpawn = function(id)
            if br.player[id].killed or not br.player[id].inGame then
                error(
                    'this player cannot be spawned (k='
                            .. tostring(br.player[id].killed) .. ' | iG=' .. tostring(br.player[id].inGame) .. ')',
                    2
                )
            end

            if not br.player[id].spawnPosition then
                local spawnx, spawny
                repeat
                    spawnx = math.random(0, map 'xsize')
                    spawny = math.random(0, map 'ysize')
                until br.funcs.game.checkIfSpawnable(spawnx, spawny)

                br.player[id].spawnPosition = {spawnx, spawny}
            end

            parse('spawnplayer ' .. id .. ' '
                    .. br.player[id].spawnPosition[1] * 32 + 16 .. ' ' .. br.player[id].spawnPosition[2] * 32 + 16)
        end,

        updateHud = function(id)
            br.player[id].ui.lastInfo = br.player[id].ui.lastInfo or {
                hp      = -1,
                armor   = -1,
                exp     = -1,
                stamina = -1,
                skins   = -1,
                hover   = '',
                cat     = -1,
                page    = -1,
            }

            local c, a = string.char(169), (br.player[id].ui.skins.opened and 0.2 or 1)
            local uiImages, uiTexts, uiConf = br.player[id].ui.images, br.player[id].ui.texts, br.config.ui

            -- Alive players
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

            local aliveText =
                    string.char(169) .. '000255000Alive: ' .. alivePlayers .. ' | ' ..
                    string.char(169) .. '255000000Dead: '  .. deadPlayers  .. ' | ' ..
                    string.char(169) .. '255255255Spec: '  .. specPlayers
            if not uiTexts.alive then
                uiTexts.alive = br.funcs.hudtext.new(id, 2, '', 415, 50, 1)
            end
            uiTexts.alive:setText(aliveText)
            uiTexts.alive:setAlpha(a)

            -- Grace period text
            local graceText
            if br.gracePeriodTimer == 0 then
                graceText = c .. '255000000The grace period is over!'
            else
                graceText = c .. '255255000Seconds left until the end of the grace period: ' .. br.gracePeriodTimer
            end

            if not uiTexts.grace then
                uiTexts.grace = br.funcs.hudtext.new(id, 1, '', 415, 65, 1)
            end
            uiTexts.grace:setText(graceText)
            uiTexts.grace:setAlpha(a)

            -- Levels UI text
            local levelData = br.funcs.player.getExpData(id)
            local expText = c .. '255165000' .. levelData.progressNextLevel .. '/' .. levelData.neededForNextLevel
            local levelText = c .. '030144255' .. levelData.currentLevel
            if not uiTexts.exp then
                uiTexts.exp = br.funcs.hudtext.new(
                    id, 3, '', uiConf.expBar.position[1] + 13, uiConf.expBar.position[2] - 1, 1, 1
                )
            end
            uiTexts.exp:setText(expText)
            uiTexts.exp:setAlpha(a)

            if not uiTexts.level then
                uiTexts.level = br.funcs.hudtext.new(
                    id, 5, '', uiConf.expBar.position[1] - 68, uiConf.expBar.position[2] - 1, 1, 1
                )
            end
            uiTexts.level:setText(levelText)
            uiTexts.level:setAlpha(a)

            -- Steam warning
            if player(id, 'steamid') == '0' then
                local warnText = c .. '255000000You\'re not logged into Steam! Your level progress will NOT be saved!'
                if not uiTexts.warn then
                    uiTexts.warn = br.funcs.hudtext.new(id, 4, '', 415, 400, 1, 1)
                end
                uiTexts.warn:setText(warnText)
                uiTexts.warn:setAlpha(a)
            end

            -- Death info
            local killedText = ''
            if br.player[id].killed then
                killedText = c .. '255000000You\'re DEAD. If you try to respawn, you will get instantly killed!'
            end

            if not uiTexts.death then
                uiTexts.death = br.funcs.hudtext.new(id, 0, '', 415, 35, 1, 0)
            end
            uiTexts.death:setText(killedText)
            uiTexts.death:setAlpha(a)

            -- Xp bar
            if not uiImages.xpBar then
                uiImages.xpBar = br.funcs.geometry.drawLine(0, 0, 0, 0, 12, 2, 0.5, {30, 144, 255}, id)
            end

            if br.player[id].ui.lastInfo.exp ~= br.player[id].storedData.exp then
                local barWidth = 128 * (levelData.progressNextLevel / levelData.neededForNextLevel)
                br.funcs.geometry.moveLine(
                    uiImages.xpBar,
                    uiConf.expBar.position[1] - 51,
                    uiConf.expBar.position[2],
                    uiConf.expBar.position[1] - 51 + barWidth,
                    uiConf.expBar.position[2]
                )
            end

            if not br.player[id].killed then
                -- Hp bar
                if not uiImages.hpBarFrame then
                    uiImages.hpBarFrame = image(
                        uiConf.progressBarImage,
                        uiConf.hpBar.position[1],
                        uiConf.hpBar.position[2],
                        2,
                        id
                    )
                end

                if not uiImages.hpBar then
                    uiImages.hpBar = br.funcs.geometry.drawLine(0, 0, 0, 0, 12, 2, 0.5, {255, 0, 0}, id)
                end

                if br.player[id].ui.lastInfo.hp ~= player(id, 'health') then
                    local hpBarWidth = 128 * (player(id, 'health') / player(id, 'maxhealth'))
                    br.funcs.geometry.moveLine(
                        uiImages.hpBar,
                        uiConf.hpBar.position[1] - 64,
                        uiConf.hpBar.position[2],
                        uiConf.hpBar.position[1] - 64 + hpBarWidth,
                        uiConf.hpBar.position[2]
                    )
                end

                local hpText = c .. '255255255' .. player(id, 'health') .. '/' .. player(id, 'maxhealth')
                if not uiTexts.hp then
                    uiTexts.hp = br.funcs.hudtext.new(
                        id, 6, '', uiConf.hpBar.position[1], uiConf.hpBar.position[2] - 1, 1, 1
                    )
                end
                uiTexts.hp:setText(hpText)
                uiTexts.hp:setAlpha(a)

                -- Armor bar
                if not uiImages.armorBarFrame then
                    uiImages.armorBarFrame = image(
                        uiConf.progressBarImage,
                        uiConf.armorBar.position[1],
                        uiConf.armorBar.position[2],
                        2,
                        id
                    )
                end

                if not uiImages.armorBar then
                    uiImages.armorBar = br.funcs.geometry.drawLine(0, 0, 0, 0, 12, 2, 0.5, {0, 0, 0}, id)
                end

                if br.player[id].ui.lastInfo.armor ~= player(id, 'armor') then
                    local armorBarWidth = 128 * (player(id, 'armor') <= 100 and player(id, 'armor') / 100 or 1)
                    br.funcs.geometry.moveLine(
                        uiImages.armorBar,
                        uiConf.armorBar.position[1] - 64,
                        uiConf.armorBar.position[2],
                        uiConf.armorBar.position[1] - 64 + armorBarWidth,
                        uiConf.armorBar.position[2]
                    )
                    br.funcs.geometry.colorLine(
                        uiImages.armorBar, player(id, 'armor') <= 200 and {0, 0, 255} or {98, 98, 98}
                    )
                end

                local armorText = c .. '255165000'
                if player(id, 'armor') < 200 then
                    armorText = player(id, 'armor') .. '/100'
                else
                    local armor = player(id, 'armor')
                    if armor == 201 then
                        armorText = armorText .. '25% reduction'
                    elseif armor == 202 then
                        armorText = armorText .. '50% reduction'
                    elseif armor == 203 then
                        armorText = armorText .. '75% reduction'
                    elseif armor == 204 then
                        armorText = armorText .. '50% reduction + heal'
                    elseif armor == 205 then
                        armorText = armorText .. '95% reduction'
                    elseif armor == 206 then
                        armorText = armorText .. 'stealth'
                    else
                        armorText = armorText .. '???'
                    end
                end
                if not uiTexts.armor then
                    uiTexts.armor = br.funcs.hudtext.new(
                        id, 7, '', uiConf.armorBar.position[1], uiConf.armorBar.position[2] - 1, 1, 1
                    )
                end
                uiTexts.armor:setText(armorText)
                uiTexts.armor:setAlpha(a)

                -- Stamina bar
                if not uiImages.stamBarFrame then
                    uiImages.stamBarFrame = image(
                        uiConf.bigProgressBarImage,
                        uiConf.stamBar.position[1],
                        uiConf.stamBar.position[2],
                        2,
                        id
                    )
                end

                if not uiImages.stamBar then
                    uiImages.stamBar = br.funcs.geometry.drawLine(
                        0, 0, 0, 0, 12, 2, 0.5, {128, 255, 128}, id
                    )
                end

                if br.player[id].ui.lastInfo.stamina ~= br.player[id].stamina then
                    local stamBarWidth = 154 * (br.player[id].stamina) / 100
                    br.funcs.geometry.moveLine(
                        uiImages.stamBar,
                        uiConf.stamBar.position[1] - 77,
                        uiConf.stamBar.position[2],
                        uiConf.stamBar.position[1] - 77 + stamBarWidth,
                        uiConf.stamBar.position[2])
                end

                local stamText = c .. '064064064' .. math.floor(br.player[id].stamina) .. '/100'
                if not uiTexts.stam then
                    uiTexts.stam = br.funcs.hudtext.new(
                        id, 8, '', uiConf.stamBar.position[1], uiConf.stamBar.position[2] - 1, 1, 1
                    )
                end
                uiTexts.stam:setText(stamText)
                uiTexts.stam:setAlpha(a)
            else
                -- Hp bar
                if uiImages.hpBarFrame then
                    freeimage(uiImages.hpBarFrame)
                    uiImages.hpBarFrame = false
                end

                if uiImages.hpBar then
                    br.funcs.geometry.freeLine(uiImages.hpBar)
                    uiImages.hpBar = false
                end

                -- Armor bar
                if uiImages.armorBarFrame then
                    freeimage(uiImages.armorBarFrame)
                    uiImages.armorBarFrame = false
                end

                if uiImages.armorBar then
                    br.funcs.geometry.freeLine(uiImages.armorBar)
                    uiImages.armorBar = false
                end

                -- Stamina bar
                if uiImages.stamBarFrame then
                    freeimage(uiImages.stamBarFrame)
                    uiImages.stamBarFrame = false
                end

                if uiImages.stamBar then
                    br.funcs.geometry.freeLine(uiImages.stamBar)
                    uiImages.stamBar = false
                end

                if br.player[id].ui.lastInfo.hp > 0 or br.player[id].ui.lastInfo.hp == -1 then
                    if uiTexts.hp then
                        uiTexts.hp:setText('')
                    end

                    if uiTexts.armor then
                        uiTexts.armor:setText('')
                    end

                    if uiTexts.stam then
                        uiTexts.stam:setText('')
                    end
                end
            end

            -- Controls info
            local sprintText = c .. '255128000[SPACE] to sprint'
            if not uiTexts.sprintInfo then
                uiTexts.sprintInfo = br.funcs.hudtext.new(id, 9, '', 90, 429, 1, 1)
            end
            uiTexts.sprintInfo:setText(sprintText)
            uiTexts.sprintInfo:setAlpha(a)

            local cosmText = c .. '255128000[F3] for cosmetics menu'
            if not uiTexts.cosmInfo then
                uiTexts.cosmInfo = br.funcs.hudtext.new(id, 10, '', 246, 429, 1, 1)
            end
            uiTexts.cosmInfo:setText(cosmText)
            uiTexts.cosmInfo:setAlpha(a)

            -- Skins menu
            local blines = {2, 2, 0.5, {0, 255, 255}, id}
            local skins, skinsConf = br.player[id].ui.skins, br.config.ui.skins
            local skinsImages, skinsTexts = br.player[id].ui.skins.images, br.player[id].ui.skins.texts
            if skins.opened and (not br.player[id].ui.lastInfo.skins or br.player[id].ui.lastInfo.skins == -1) then
                -- Menu itself
                if not skinsImages.menu then
                    skinsImages.menu = image(
                        br.config.skinsMenuImage, skinsConf.position[1], skinsConf.position[2], 2, id
                    )

                    imagealpha(skinsImages.menu, 0)
                    imagescale(skinsImages.menu, skinsConf.scale[1], skinsConf.scale[2])
                end
                imagealpha(skinsImages.menu, 0.9)

                -- Exit
                local exit = skinsConf.exit
                local cx = math.floor(exit.box[1] + (exit.box[3] - exit.box[1]) / 2)
                local cy = math.floor(exit.box[2] + (exit.box[4] - exit.box[2]) / 2)
                if not skinsTexts.exit then
                    skinsTexts.exit = br.funcs.hudtext.new(id, 20, '', cx, cy, 1, 1, 20)
                end
                skinsTexts.exit:setText('Exit')

                -- Categories
                for k, v in pairs(skinsConf.categories) do
                    local key = 'cat' .. k
                    if not skinsTexts[key] then
                        local cx = math.floor(v.box[1] + (v.box[3] - v.box[1]) / 2)
                        local cy = math.floor(v.box[2] + (v.box[4] - v.box[2]) / 2)
                        skinsTexts[key] = br.funcs.hudtext.new(id, 20 + k, '', cx, cy, 1, 1, 15)
                    end
                    skinsTexts[key]:setText(v.name)
                end

                -- Page display
                if not skinsTexts.page then
                    skinsTexts.page = br.funcs.hudtext.new(
                        id, 25, '', skinsConf.misc.page[1], skinsConf.misc.page[2], 1, 1, 12
                    )
                end
                skinsTexts.page:setText('x/y')

                -- Level display
                if not skinsTexts.level then
                    skinsTexts.level = br.funcs.hudtext.new(
                        id, 26, '', skinsConf.misc.level[1], skinsConf.misc.level[2], 1, 1, 12
                    )
                end
                skinsTexts.level:setText('Level: ' .. br.funcs.player.getExpData(id).currentLevel)

                -- Gold display
                if not skinsTexts.gold then
                    skinsTexts.gold = br.funcs.hudtext.new(
                        id, 27, '', skinsConf.misc.gold[1], skinsConf.misc.gold[2], 1, 1, 12
                    )
                end
                skinsTexts.gold:setText('Gold: ' .. br.player[id].storedData.gold)
            elseif not skins.opened and (br.player[id].ui.lastInfo.skins or br.player[id].ui.lastInfo.skins == -1) then
                -- Hide highlights
                for k, v in pairs({
                    'menu',
                    'catHigh',
                    'catHov',
                    'exitHov'
                }) do
                    if skinsImages[v] then
                        imagealpha(skinsImages[v], 0)
                    end
                end

                -- Remove texts
                for _, text in pairs(skinsTexts) do
                    text:setText('')
                end
            end

            if skins.opened then
                if br.player[id].ui.lastInfo.cat ~= skins.cat
                    or skins.opened and not br.player[id].ui.lastInfo.skins then
                    -- Selected category highlight
                    if not skinsImages.catHigh then
                        skinsImages.catHigh = image(br.config.hoverCatImage, 0, 0, 2, id)
                        imagecolor(skinsImages.catHigh, 128, 255, 0)
                        imagescale(skinsImages.catHigh, skinsConf.scale[1], skinsConf.scale[2])
                    end
                    local cat = skinsConf.categories[tonumber(br.player[id].ui.skins.cat)]
                    local x, y = cat.box[1] + (cat.box[3] - cat.box[1]) / 2, cat.box[2] + (cat.box[4] - cat.box[2]) / 2
                    imagepos(skinsImages.catHigh, x, y, 0)
                    imagealpha(skinsImages.catHigh, 0.15)
                end

                if skins.hover:sub(1, 3) == 'cat' and br.player[id].ui.lastInfo.hover ~= skins.hover then
                    if not skinsImages.catHov then
                        skinsImages.catHov = image(br.config.hoverCatImage, 0, 0, 2, id)
                        imagescale(skinsImages.catHov, skinsConf.scale[1], skinsConf.scale[2])
                    end
                    local cat = skinsConf.categories[tonumber(skins.hover:sub(4))]
                    local x = cat.box[1] + (cat.box[3] - cat.box[1]) / 2
                    local y = cat.box[2] + (cat.box[4] - cat.box[2]) / 2
                    imagepos(skinsImages.catHov, x, y, 0)
                    imagealpha(skinsImages.catHov, 0.1)
                elseif skins.hover:sub(1, 3) ~= 'cat' and br.player[id].ui.lastInfo.hover:sub(1, 3) == 'cat' then
                    if skinsImages.catHov then
                        imagealpha(skinsImages.catHov, 0)
                    end
                end

                if skins.hover == 'exit' and br.player[id].ui.lastInfo.hover ~= skins.hover then
                    if not skinsImages.exitHov then
                        skinsImages.exitHov = image(br.config.hoverExitImage, 0, 0, 2, id)
                        imagescale(skinsImages.exitHov, skinsConf.scale[1], skinsConf.scale[2])
                    end
                    local exit = skinsConf.exit
                    local x = exit.box[1] + (exit.box[3] - exit.box[1]) / 2
                    local y = exit.box[2] + (exit.box[4] - exit.box[2]) / 2
                    imagepos(skinsImages.exitHov, x, y, 0)
                    imagealpha(skinsImages.exitHov, 0.1)
                elseif skins.hover ~= 'exit' and br.player[id].ui.lastInfo.hover == 'exit' then
                    if skinsImages.exitHov then
                        imagealpha(skinsImages.exitHov, 0)
                    end
                end
            end

            br.player[id].ui.lastInfo = {
                hp      = player(id, 'health'),
                armor   = player(id, 'armor'),
                exp     = br.player[id].storedData.exp,
                stamina = br.player[id].stamina,
                skins   = br.player[id].ui.skins.opened,
                hover   = br.player[id].ui.skins.hover,
                cat     = br.player[id].ui.skins.cat,
                page    = br.player[id].ui.skins.page
            }
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
                spawnPosition    = false,

                auraImage        = false,
                stamina          = 0,
                sprinting        = false,

                storedData       = {},
                loadedStoredData = false,
                role             = 'player',

                ui               = {
                    images = {},
                    texts  = {},
                    skins  = {
                        opened = false,
                        hover  = 'none',
                        cat    = 1,
                        page   = 1,
                        images = {},
                        texts  = {}
                    }
                },
            }
        end,

        getStoredDataSchema = function()
            return {
                exp  = 0,
                aura = 0,
                gold = 0
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
        end
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
