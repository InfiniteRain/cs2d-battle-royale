function class(constructor)
    namespace = {}
    namespace.__index = namespace
    namespace.new = function(...)
        local outerSelf = self
        -- aliases
        local this = {}
        self = this
        -- finish
        setmetatable(this,namespace)
        constructor(unpack(arg))
        self = outerSelf -- used to allow constructors inside constructors
        return this
    end
    return namespace
end

function classExtends(extend,constructor)
    namespace = {}
    namespace.__index = namespace
    namespace.new = function(...)
        local outerSelf = self
        -- aliases
        local this = extend.new()
        self = this
        -- finish
        --setmetatable(this,namespace)
        constructor(unpack(arg))
        self = outerSelf -- used to allow constructors inside constructors
        return this
    end
    return namespace
end
