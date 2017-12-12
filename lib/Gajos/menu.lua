-- model --
local MenuModel = function(controller, user_id)
    local self = setmetatable({}, MenuModel)

    self.controller = controller
    self.user_id = user_id
    self.type = ''
    self.title = ''
    self.noskip = false
    self.buttons = {}

    function self:addButton(name, desc, onClick, visible)
        local name = name:gsub('|', 'l'):gsub(',', '.')
        local desc = desc:gsub('|', 'l'):gsub(',', '.')

        local str = name .. '|' .. desc
        if not visible then
            str = '(' .. str .. ')'
        end

        table.insert(self.buttons, {
            name = name:gsub('|', 'l'):gsub(',', '.'),
            desc = desc:gsub('|', 'l'):gsub(',', '.'),
            str = str,
            onClick = onClick,
        })
    end

    function self:setType(type)
        switch(type) {
            large = function()
                self.type = '@b'
            end,

            invisible = function()
                self.type = '@i'
            end,

            [Default] = function()
                self.type = ''
            end,
        }
    end

    function self:setTitle(title)
        self.title = title
    end

    function self:setNoskip(state)
        self.noskip = state
    end

    function self:show()
        self.view:show()
    end

    function self:onMenu(page, btn, are_pages)
        if btn == 0 then
            if self.noskip then
                local function func()
                    controller:show(page)
                end
                br.timer.new(16, func, 1)
            end

            return
        end

        if not are_pages then
            local func = self.buttons[btn].onClick

            if func then
                func(user_id)
            end
        else
            if btn <= 7 then
                self.buttons[(page - 1) * 7 + btn].onClick(user_id)
            else
                controller:show(page + 1)
            end
        end
    end

    return self
end
__index = MenuModel

-- view --
local MenuView = function(user_id)
    local self = setmetatable({}, MenuView)

    self.user_id = user_id

    function self:show(title, menu_type, buttons, page)
        page = (not page or page > math.ceil(#buttons / 7)) and 1 or page

        local loop_start, loop_end
        local custom_title, custom_str = '', ''
        if #buttons <= 9 then
            loop_start = 1
            loop_end = 9
        else
            loop_start = page * 7 - 6
            loop_end = page * 7
            custom_title = ' #' .. page
            if math.ceil(#buttons / 7) == page then for i = 1, 7 - #buttons % 7 do
                custom_str = custom_str .. ','
            end end
            custom_str = custom_str .. ',,Next|\187'
        end

        local tab = {}
        for i = loop_start, loop_end do
            local button = buttons[i]
            if not button then break end

            table.insert(tab, button.str)
        end

        menu(user_id, title .. custom_title .. menu_type .. ',' ..  table.concat(tab, ',') .. custom_str)
    end

    return self
end
__index = MenuView

-- controller --
local users = {}
for id = 1, 32 do
    users[id] = {}
end

local MenuController = function(user_id, title, noskip)
    local self = setmetatable({}, MenuController)

    self.user_id = user_id
    self.model = MenuModel(self, user_id)
    self.view = MenuView(user_id)

    function self:addButton(name, desc, onClick, visible)
        self.model:addButton(name, desc, onClick, (visible == nil) and true or visible)
    end

    function self:setMenuType(type)
        self.model:setType(type)
    end

    function self:setNoskip(state)
        self.model:setNoskip(state)
    end

    function self:noskip()
        self:setNoskip(true)
    end

    function self:show(page)
        self.view:show(self.model.title, self.model.type, self.model.buttons, page)
        users[user_id].cached_menu = self
    end

    function self:onMenu(t, btn)
        local are_pages = t:find('#')
        local page = 1

        if are_pages then
            page = tonumber(br.misc.toTable(t, '#')[2])
        end

        self.model:onMenu(page, btn, are_pages)
        -- users[user_id].cached_menu = false
    end

    -- constructor
    self.model:setTitle(title)
    self:setNoskip(noskip or false)

    return self
end
-- MenuController.__index = MenuController

return
{
    new = MenuController,
    users = users,
}
