br = {
	player           = {},
	restarting       = false,
	areaCenter       = {0, 0},
	areaRadius       = 0,
	areaCircleImage  = false,
	packages         = {},
    gracePeriodTimer = 0,
    roundEnded       = false,

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
