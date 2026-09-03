-- Registry for controls exposed by the Hoomans map menu.

PNC = PNC or {}
PNC.MapHoomansMenu = PNC.MapHoomansMenu or {}

local Menu = PNC.MapHoomansMenu
Menu.EntriesByID = Menu.EntriesByID or {}

local function resolve(entry, field, fallback)
    local value = entry and entry[field]
    if type(value) == "function" then value = value(entry) end
    if value == nil then return fallback end
    return value
end

function Menu.Resolve(entry, field, fallback)
    return resolve(entry, field, fallback)
end

function Menu.IsEntryVisible(entry)
    return resolve(entry, "visible", true) ~= false
end

function Menu.List()
    local entries = {}
    for _, entry in pairs(Menu.EntriesByID) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(left, right)
        if left.order ~= right.order then return left.order < right.order end
        return tostring(left.id) < tostring(right.id)
    end)
    return entries
end

function Menu.VisibleEntryCount()
    local count = 0
    for _, entry in ipairs(Menu.List()) do
        if Menu.IsEntryVisible(entry) then count = count + 1 end
    end
    return count
end

function Menu.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.onActivate) ~= "function"
    then
        return false
    end
    definition.id = id
    definition.order = tonumber(definition.order) or 100
    Menu.EntriesByID[id] = definition
    if Menu.instance and Menu.instance.syncButtons then
        Menu.instance:syncButtons()
    end
    return true
end

function Menu.Unregister(id)
    id = tostring(id or "")
    if not Menu.EntriesByID[id] then return false end
    Menu.EntriesByID[id] = nil
    if Menu.instance and Menu.instance.syncButtons then
        Menu.instance:syncButtons()
    end
    return true
end

return Menu
