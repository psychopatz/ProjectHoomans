PNC = PNC or {}
PNC.ColonyManagementUI = PNC.ColonyManagementUI or {}

local ColonyUI = PNC.ColonyManagementUI
local Registry = ColonyUI.TabRegistry or { ordered = {}, byID = {} }
ColonyUI.TabRegistry = Registry

function Registry.Register(definition)
    if type(definition) ~= "table" then return false end
    local id = tostring(definition.id or "")
    if id == "" or Registry.byID[id] then return false end
    definition.id = id
    Registry.byID[id] = definition
    Registry.ordered[#Registry.ordered + 1] = definition
    return true
end

function Registry.Get(id)
    return Registry.byID[tostring(id or "")]
end

function Registry.All()
    return Registry.ordered
end

function ColonyUI.RegisterTab(definition)
    return Registry.Register(definition)
end

return Registry
