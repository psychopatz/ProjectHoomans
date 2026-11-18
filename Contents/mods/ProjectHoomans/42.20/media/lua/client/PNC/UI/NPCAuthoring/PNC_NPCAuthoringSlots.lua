-- Human presentation over native/modded slot identities; storage IDs stay exact.
PNC.NPCAuthoringSlots = PNC.NPCAuthoringSlots or {}
local Slots = PNC.NPCAuthoringSlots
local Catalog = PNC.NPCAuthoringCatalog
local function tr(key, fallback) return PNC.Translation.GetKey(key, fallback) end
local groups = {
    { id = 'head', key = 'Head', label = 'Head and face', pattern = 'hat|head|mask|eyes|eye|ears|ear|nose' },
    { id = 'neck', key = 'Neck', label = 'Neck', pattern = 'neck|scarf|gorget' },
    { id = 'hands', key = 'Hands', label = 'Hands and jewelry', pattern = 'hand|finger|wrist|forearm' },
    { id = 'back', key = 'Back', label = 'Back and bags', pattern = 'back|fanny|webbing' },
    { id = 'waist', key = 'Waist', label = 'Waist and holsters', pattern = 'belt|holster|ammo|strap' },
    { id = 'feet', key = 'Feet', label = 'Feet', pattern = 'shoe|sock|foot' },
    { id = 'legs', key = 'Legs', label = 'Legs', pattern = 'pants|skirt|leg|thigh|knee|calf|shorts' },
    { id = 'torso', key = 'Torso', label = 'Torso and layers', pattern = 'shirt|vest|jacket|torso|suit|sweater|dress|underwear|robe' },
    { id = 'other', key = 'Other', label = 'Other equipment', pattern = '' },
}
function Slots.Group(location)
    local raw = string.lower(location)
    for _, group in ipairs(groups) do
        for token in string.gmatch(group.pattern, '[^|]+') do
            if string.find(raw, token, 1, true) then return group end
        end
    end
    return groups[#groups]
end
function Slots.Groups() return groups end
local nativeNames, nativeCount, nativeGroup = {}, -1, nil
local function translationName(location)
    local group = BodyLocations and BodyLocations.getGroup and BodyLocations.getGroup('Human')
    if group and (group ~= nativeGroup or group:size() ~= nativeCount) then
        nativeNames, nativeGroup, nativeCount = {}, group, group:size()
        for index = 0, nativeCount - 1 do
            local entry = group:getLocationByIndex(index)
            local id = entry and entry:getId()
            if id and id.getTranslationName then
                local key = string.lower(string.match(tostring(id), '([^:]+)$') or tostring(id))
                nativeNames[key] = id:getTranslationName()
            end
        end
    end
    return nativeNames[string.lower(string.match(location, '([^:]+)$') or location)]
end
function Slots.Label(location)
    local worn = PNC.Equipment.NormalizeLoadoutSpec({ worn = { [location] = '_' } }).worn
    local canonical
    for key in pairs(worn) do canonical = key end
    local short = string.match(canonical or location, '([^:]+)$') or location
    local key = 'UI_ClothingType_' .. (translationName(location) or short)
    local label = getText(key)
    if label == key then
        label = string.gsub(short, '_', ' ')
        label = string.gsub(label, '([a-z])([A-Z])', '%1 %2')
        label = string.upper(string.sub(label, 1, 1)) .. string.sub(label, 2)
    end
    return label
end
function Slots.Build(draft, record)
    local rows, seen = {}, {}
    local effective = record and record.inventory and record.inventory.items or {}
    local function add(location)
        local identity = string.lower(string.match(location, '([^:]+)$') or location)
        if seen[identity] then return end
        seen[identity] = true
        local options = Catalog.Clothing(location)
        local selected
        local normalized = string.lower(string.match(location, '([^:]+)$') or location)
        for _, item in pairs(effective) do
            local worn = item.wornSlot and string.lower(string.match(item.wornSlot, '([^:]+)$') or item.wornSlot)
            if worn == normalized then selected = item.type end
        end
        for _, item in ipairs(draft.startingItems or {}) do if item.wornSlot and string.lower(string.match(item.wornSlot, '([^:]+)$') or item.wornSlot) == identity then selected = item.type end end
        local policy, policyID
        for id, value in pairs(draft.appearance and draft.appearance.slots or {}) do
            if string.lower(string.match(id, '([^:]+)$') or id) == identity then policy, policyID = value, id end
        end
        if policy and policy.mode == 'item' then selected = policy.type end
        if policy and policy.mode == 'none' then selected = nil end
        if #options > 0 or selected then
            rows[#rows + 1] = { kind = 'worn', id = policyID or location, label = Slots.Label(location),
                group = Slots.Group(location).id, type = selected }
        end
    end
    for _, location in ipairs(PNC.UniqueNPCAppearanceUI.Internal.locations()) do add(location) end
    for _, item in pairs(effective) do if item.wornSlot then add(item.wornSlot) end end
    for _, item in ipairs(draft.startingItems or {}) do if item.wornSlot then add(item.wornSlot) end end
    table.sort(rows, function(a, b) return a.label < b.label end)
    for _, id in ipairs({ 'primary', 'secondary' }) do
        local kind = id == 'primary' and 'Primary' or 'Secondary'
        local row = { kind = 'held', id = id, group = 'held', label = tr('UI_PNC_Authoring_' .. kind,
            id == 'primary' and 'Primary hand' or 'Secondary hand') }
        for _, item in pairs(effective) do if item.equipSlot == id then row.type = item.type end end
        for _, item in ipairs(draft.startingItems or {}) do if item.equipSlot == id then row.type = item.type end end
        rows[#rows + 1] = row
    end
    rows[#rows + 1] = { kind = 'attach', id = 'auto', group = 'held', label = tr('UI_PNC_Authoring_Attach', 'Add attachment') }
    for index, item in ipairs(draft.startingItems or {}) do
        if not item.wornSlot and not item.equipSlot then rows[#rows + 1] = { kind = 'item', id = item.key or 'item:' .. index,
            index = index, group = item.attachedSlot and 'held' or 'carry',
            label = item.attachedSlot and Slots.Label(item.attachedSlot) or '×' .. tostring(item.stack or 1), type = item.type } end
    end
    rows[#rows + 1] = { kind = 'carry', id = 'new', group = 'carry', label = tr('UI_PNC_Authoring_AddItem', 'Add carried item or bag') }
    return rows
end
return Slots
