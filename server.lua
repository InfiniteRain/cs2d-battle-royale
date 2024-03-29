br = {
    player           = {},
    teams            = {},
    safeZone         = false,
    shrinkStarted    = false,
    packages         = {},
    gracePeriodTimer = 0,
    roundEnded       = false,

    gpTimerFrame     = -1,
    gpTimerFont      = false,

    expBar           = false,
    trains           = {}
}

br.config   = assert(loadfile('sys/lua/battle_royale/config.lua'))()
br.commands = assert(loadfile('sys/lua/battle_royale/commands.lua'))()
br.funcs    = assert(loadfile('sys/lua/battle_royale/funcs.lua'))()
br.hooks    = assert(loadfile('sys/lua/battle_royale/hooks.lua'))()
br.settings = assert(loadfile('sys/lua/battle_royale/settings.lua'))()

for hook, _ in pairs(br.hooks) do
    addhook(hook, 'br.hooks.' .. hook)
end

addbind('space')
addbind('escape')
addbind('mouse1')

for setting, values in pairs(br.settings) do
    local vals = (type(values) ~= 'table' and {values} or values)
    parse(setting ..' '.. table.concat(vals, ' '))
end

for i = 1, 32 do
    br.player[i] = br.funcs.player.getDataSchema()
end

for pattern, conf in pairs(br.config.maps) do
    if map('name'):match(pattern) then
        for _, train in pairs(conf.trains or {}) do
            local angle = br.funcs.geometry.getAngle(
                train.start[1],
                train.start[2],
                train.finish[1],
                train.finish[2]
            )

            table.insert(br.trains, {
                image = false,
                angle = angle,
                realStart = {br.funcs.geometry.extendPosition(
                    train.start[1] * 32 + 16,
                    train.start[2] * 32 + 16,
                    angle,
                    -train.size[2]/2
                )},
                realFinish = {br.funcs.geometry.extendPosition(
                    train.finish[1] * 32 + 16,
                    train.finish[2] * 32 + 16,
                    angle,
                    train.size[2]/2
                )},

                running = false,
                startedAt = 0,
                finishesIn = 0,
                config = train,
            })
        end
    end

    break
end

br.funcs.server.checkServertransfer()
parse('sv_restart')
