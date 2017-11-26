br = {
    player           = {},
    restarting       = false,
    safeZone         = false,
    shrinkStarted    = false,
    packages         = {},
    gracePeriodTimer = 0,
    roundEnded       = false,
    
    gpTimerFrame     = -1,
    gpTimerFont      = false,

    config = loadfile('sys/lua/battle_royale/config.lua')(),
    funcs = loadfile('sys/lua/battle_royale/funcs.lua')(),
    hooks = loadfile('sys/lua/battle_royale/hooks.lua')(),
    settings = loadfile('sys/lua/battle_royale/settings.lua')()
}

for hook, _ in pairs(br.hooks) do
    addhook(hook, 'br.hooks.' .. hook)
end

for setting, values in pairs(br.settings) do
    parse(setting ..' '.. table.concat(values, ' '))
end

for i = 1, 32 do
    br.player[i] = br.funcs.player.getStandardPlayerData()
end

br.funcs.server.checkServertransfer()
parse('sv_restart')
