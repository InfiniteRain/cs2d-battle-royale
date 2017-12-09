local newTeam = function(user)
    local self = setmetatable({}, MenuController)

    self.user = user

    local test = user.newMenu('Test menu')
    test:addButton('btn1', 'desc1', false)
    test:show()
end

return
{
    new = newTeam,
}