return 

{
    {
        command = 'exec',
        roles   = {'admin'},
        func    = function(id, role, args)
            parse(table.concat(args, ' '))
        end
    },
    {
        command = 'kick',
        roles   = {'admin'},
        func    = function(id, role, args)
            parse('kick ' .. args[1])
        end
    },
    {
        command = 'ban',
        roles   = {'admin'},
        func    = function(id, role, args)
            local pl = tonumber(args[1])
            local duration = tonumber(args[2] or 0)

            local usgn = player(pl, 'usgn')
            local steamid = player(pl, 'steamid')
            local name = player(pl, 'name')

            if usgn ~= 0 then
                parse('banusgn ' .. usgn .. ' ' .. duration)
            end

            if steamid ~= '0' then
                parse('bansteam ' .. usgn .. ' ' .. duration)
            end

            parse('banname "' .. name .. '" ' .. duration)
        end
    }
}
