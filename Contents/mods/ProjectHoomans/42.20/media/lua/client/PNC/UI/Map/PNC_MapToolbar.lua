-- Hoomans compatibility facade over PsychopatzCore's shared map tools.
-- Core owns ISWorldMap lifecycle hooks; Hoomans only registers its tools.

local Host = require "PsychopatzCore/UI/Map/PsychopatzMapHost"

PNC = PNC or {}
PNC.MapToolbar = PNC.MapToolbar or {}

local Toolbar = PNC.MapToolbar
local CoreTools = Host.Tools or PsychopatzCore.MapToolRegistry

Toolbar.EntriesByID = Toolbar.EntriesByID or {}

local function coreID(id)
    return "ProjectHoomans:" .. tostring(id or "")
end

function Toolbar.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.onActivate) ~= "function"
    then
        return false
    end
    definition.id = id
    definition.order = tonumber(definition.order) or 100
    definition.field = definition.field or ("pnc" .. id .. "Button")
    Toolbar.EntriesByID[id] = definition

    local coreDefinition = {}
    for key, value in pairs(definition) do
        coreDefinition[key] = value
    end
    return CoreTools.Register(coreID(id), coreDefinition)
end

function Toolbar.Unregister(id)
    id = tostring(id or "")
    if id == "" or not Toolbar.EntriesByID[id] then return false end
    Toolbar.EntriesByID[id] = nil
    CoreTools.Unregister(coreID(id))
    return true
end

function Toolbar.List()
    local entries = {}
    for _, entry in pairs(Toolbar.EntriesByID) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(left, right)
        if left.order ~= right.order then return left.order < right.order end
        return tostring(left.id) < tostring(right.id)
    end)
    return entries
end

function Toolbar.LayoutButtons(map)
    return CoreTools.LayoutButtons(map)
end

function Toolbar.EnsureButtons(map)
    return CoreTools.EnsureButtons(map)
end

function Toolbar.Close()
    return CoreTools.Close()
end

return Toolbar
