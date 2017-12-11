local users = {}
for id = 1, 32 do
    users[id] = {}
end

local namespace = {

}
local removeValue = function(tab, val)
    for _, v in pairs(tab) do
        if v == val then
            table.remove(tab, _)
            return
        end
    end
end

local drawAura = function(id, r, g, b)
    local user = users[id]

    if user.aura_img then
        freeimage(user.aura_img)
        user.aura_img = false
    end

    if r and g and b then
        user.aura_img = image(br.config.auraImage, 0, 0, 100 + id)
        imageblend(user.aura_img, 1)
        imagecolor(user.aura_img, r, g, b)
        imagealpha(user.aura_img, 0.6)
    end
end

local newTeam = function(name, r, g, b)
    local self = setmetatable({}, newTeam)

    self.name = name
    self.r, self.g, self.b = r, g, b
    self.owner = false
    self.members = {}
    self.invitations = {}

    function self:setOwner(id)
        self.owner = id
        return true
    end

    function self:addMember(id)
        local user = users[id]

        if #self.members < 4 then
            user.team = self
            drawAura(id, self.r, self.g, self.b)
            table.insert(self.members, id)

            return true
        end
        return false
    end

    function self:removeMember(id)
        local user = users[id]

        user.team = false
        drawAura(id, false)
        removeValue(self.members, id)
    end

    function self:addInvitation(id)
        local user = users[id]

        user.invitation_team = team
        table.insert(self.invitations, id)
    end

    function self:removeInvitation(id)
        removeInvitations(id)
        removeValue(self.invitations, id)
    end

    return self
end
-- newTeam.__index = newTeam

local isTeammate = function(id, pl)
    local team1 = users[id].team
    local team2 = users[pl].team

    if team1 == team2 then
        return true
    end

    return false
end

local getTeam = function(id)
    if users[id].team then
        return users[id].team
    end
    return false
end

local isOwner = function(id)
    if users[id].team.owner == id then
        return true
    end
    return false
end

local removeInvitations = function(id)
    local user = users[id]

    if user.invitation_team then
        user.invitation_team:removeInvitation(id)
        user.invitation_team = false
    end
end

-- menus --
local openMenu_teamList = function(id)
    local user = br.player[id]
    local menu = user.newMenu('Team list')

    for _, v in pairs(br.teams) do
        local n_members = #v.members

        menu:addButton(v.name, n_members .. '/4', function()
            local team = br.teams[v.name]

            if n_members == 0 then
                team:setOwner(id)
                team:addMember(id)
            else
                removeInvitations(id)
                team:addInvitation(id)
            end

        end, not(n_members == 4))
    end

    menu:show()
end

local openMenu_manageTeam = function(id)
    local user = br.player[id]
    local team = users[id].team

    local menu = user.newMenu(team.name .. ' Team')

    for _, v in pairs(team.members) do
        menu:addButton(player(v, 'name'):gsub('|', 'l'):gsub(',', '.'), 'kick', function()
            team:removeMember(v)
        end, isOwner(id) and (v ~= id))

        menu:addButton('', '', false)
        menu:addButton('Leave', '', function()
            team:removeMember(id)
        end)
    end

    menu:show()
end

local openMenu_invitations = function(id)

end

local openMenu = function(id)
    local user = br.player[id]
    local team = getTeam(id)

    if not team then
        openMenu_teamList(id)
    else
        if isOwner(id) and #team.invitations > 0 then
            openMenu_invitations(id)
        else
            openMenu_manageTeam(id)
        end
    end
end

return
{
    new = newTeam,
    isTeammate = isTeammate,
    getTeam = getTeam,
    openMenu = openMenu,
}
