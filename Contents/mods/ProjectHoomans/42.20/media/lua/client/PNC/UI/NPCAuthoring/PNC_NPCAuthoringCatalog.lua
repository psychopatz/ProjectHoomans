-- Script definitions are available before a player exists. Build once per UI
-- session; searches return at most 200 rows and never instantiate the catalog.
PNC.NPCAuthoringCatalog = PNC.NPCAuthoringCatalog or {}
local Catalog = PNC.NPCAuthoringCatalog
local entries
local clothing = {}

function Catalog.Clothing(location)
    if not clothing[location] then
        clothing[location] = PNC.UniqueNPCAppearanceUI.Internal.itemOptions(location)
    end
    return clothing[location]
end

function Catalog.Items()
    if entries then return entries end
    entries = {}
    local items = getAllItems and getAllItems() or nil
    if not items then return entries end
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if not item:getObsolete() and not item:isHidden() then
            local id = item:getFullName()
            local label = item:getDisplayName() or id
            entries[#entries + 1] = { id = id, label = label,
                search = string.lower(label .. " " .. id), script = item }
        end
    end
    table.sort(entries, function(a, b) return a.search < b.search end)
    return entries
end

function Catalog.Search(query, allowed)
    local out = {}
    query = string.lower(tostring(query or ""))
    local truncated = false
    for _, item in ipairs(Catalog.Items()) do
        if (not allowed or allowed[item.id])
            and (query == "" or string.find(item.search, query, 1, true))
        then
            if #out == 200 then truncated = true; break end
            out[#out + 1] = item
        end
    end
    return out, truncated
end

return Catalog
