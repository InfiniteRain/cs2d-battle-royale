br = {
    player           = {},
    safeZone         = false,
    shrinkStarted    = false,
    packages         = {},
    gracePeriodTimer = 0,
    roundEnded       = false,
    
    gpTimerFrame     = -1,
    gpTimerFont      = false,

    config   = assert(loadfile('sys/lua/battle_royale/config.lua'))(),
    commands = assert(loadfile('sys/lua/battle_royale/commands.lua'))(),
    funcs    = assert(loadfile('sys/lua/battle_royale/funcs.lua'))(),
    hooks    = assert(loadfile('sys/lua/battle_royale/hooks.lua'))(),
    settings = assert(loadfile('sys/lua/battle_royale/settings.lua'))()
}

-- libs
for name in io.enumdir('sys/lua/battle_royale/lib/') do
    if name ~= '.' and name ~= '..' then
        if name:sub(-4) == '.lua' then
            dofile('sys/lua/battle_royale/lib/' .. name)
        end
    end
end

for hook, _ in pairs(br.hooks) do
    addhook(hook, 'br.hooks.' .. hook)
end

for setting, values in pairs(br.settings) do
    local vals = (type(values) ~= 'table' and {values} or values)
    parse(setting ..' '.. table.concat(vals, ' '))
end

for i = 1, 32 do
    br.player[i] = br.funcs.player.getDataSchema()
end

br.funcs.server.checkServertransfer()
parse('sv_restart')
