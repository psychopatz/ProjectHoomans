-- Shared vocabulary and primitive contract for semantic camping targets.
--
-- This module intentionally knows nothing about IsoGridSquare, pathing, or
-- orders. It gives the client, server, and dialogue layer one small shape for
-- describing a room or a campfire without retaining Java objects.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local CampSite = PNC.Semantics.CampSite or {}
PNC.Semantics.CampSite = CampSite

CampSite.VERSION = 1
CampSite.KIND = "camp_site"
CampSite.SCOPES = {
    HERE = "here",
    ROOM = "room",
    CAMPFIRE = "campfire",
}
CampSite.MAX_LABEL = 64
CampSite.MAX_QUERY = 64

CampSite.RoomTypes = CampSite.RoomTypes or {}
CampSite.RoomAliases = CampSite.RoomAliases or {}

local function text(value, maximum)
    local result = tostring(value or "")
    result = string.sub(result, 1, tonumber(maximum) or #result)
    return result ~= "" and result or nil
end

local function normalizeText(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w%s]", " ")
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "^(the|a|an)%s+", "")
    return value
end

local function compact(value)
    return string.gsub(normalizeText(value), "%s+", "")
end

local function normalizedID(value)
    value = string.upper(tostring(value or ""))
    value = string.gsub(value, "[%s%-]+", "_")
    return value
end

local function roomTypeID(value)
    local result = normalizedID(value)
    if string.sub(result, 1, 5) == "ROOM_" then
        result = string.sub(result, 6)
    end
    return result
end

function CampSite.NormalizeText(value)
    return normalizeText(value)
end

function CampSite.IsHereQuery(value)
    value = normalizeText(value)
    return value == "here"
        or value == "right here"
        or value == "this place"
        or value == "this spot"
        or value == "here now"
        or value == "right here now"
        or value == "this place now"
        or value == "this spot now"
end

-- Parser grammar is intentionally permissive around prepositions, so a
-- deictic phrase can occasionally arrive with the room-capture fields filled
-- in (for example, "camp in here"). Normalize that boundary once so client
-- hints and server resolution agree that it means a generic nearby site.
function CampSite.NormalizeTarget(target)
    local value
    local query
    local scope
    local hasRoomSelector
    local output
    if type(target) ~= "table" then return target end
    value = target.roomQuery or target.query
        or target.roomType or target.roomName
    if type(value) == "table" then
        value = value.text or value.value or value.concept
    end
    query = normalizeText(value)
    scope = CampSite.NormalizeScope(target.scope or target.siteScope)
    hasRoomSelector = target.query ~= nil
        or target.roomQuery ~= nil
        or target.roomType ~= nil
        or target.roomID ~= nil
        or target.roomName ~= nil
    if not CampSite.IsHereQuery(query)
        or target.roomID ~= nil
        or target.siteID ~= nil
        or (scope ~= nil and scope ~= "room")
    then
        return target
    end
    if not hasRoomSelector and scope ~= "room" then return target end
    output = {}
    for key, child in pairs(target) do output[key] = child end
    output.scope = CampSite.SCOPES.HERE
    output.siteScope = CampSite.SCOPES.HERE
    output.query = nil
    output.roomQuery = nil
    output.roomType = nil
    output.roomName = nil
    return output
end

function CampSite.RegisterRoomType(id, definition)
    local roomID = roomTypeID(id)
    local existing
    local aliases
    local alias
    local key
    local seenAliases = {}
    if roomID == "" or type(definition) ~= "table" then
        return false, "invalid_room_type"
    end

    existing = CampSite.RoomTypes[roomID] or {}
    existing.id = roomID
    existing.label = text(definition.label or existing.label or roomID, 48)
    existing.labelKey = text(definition.labelKey or existing.labelKey, 96)
    existing.aliases = existing.aliases or {}
    for _, existingAlias in ipairs(existing.aliases) do
        key = normalizeText(existingAlias)
        if key ~= "" then seenAliases[key] = true end
    end
    aliases = definition.aliases or { definition.label or roomID }
    for _, aliasValue in ipairs(aliases) do
        alias = text(aliasValue, CampSite.MAX_QUERY)
        key = normalizeText(alias)
        if alias and key ~= "" then
            if not seenAliases[key] then
                existing.aliases[#existing.aliases + 1] = alias
                seenAliases[key] = true
            end
            CampSite.RoomAliases[key] = roomID
            CampSite.RoomAliases[compact(alias)] = roomID
        end
    end
    CampSite.RoomAliases[normalizeText(roomID)] = roomID
    CampSite.RoomAliases[compact(roomID)] = roomID
    CampSite.RoomTypes[roomID] = existing
    return true, existing
end

-- These are game vocabulary defaults, not parser branches. A later domain
-- module may register more names without changing the geometry adapter.
CampSite.RegisterRoomType("BEDROOM", {
    label = "bedroom",
    aliases = { "bedroom", "bed room", "sleeping room", "sleeping quarters" },
})
CampSite.RegisterRoomType("BATHROOM", {
    label = "bathroom",
    aliases = { "bathroom", "bath room", "washroom", "restroom", "toilet" },
})
CampSite.RegisterRoomType("LIVING_ROOM", {
    label = "living room",
    aliases = { "living room", "livingroom", "lounge", "sitting room" },
})
CampSite.RegisterRoomType("KITCHEN", {
    label = "kitchen",
    aliases = { "kitchen" },
})
CampSite.RegisterRoomType("DINING_ROOM", {
    label = "dining room",
    aliases = { "dining room", "diningroom", "dining area" },
})
CampSite.RegisterRoomType("GARAGE", {
    label = "garage",
    aliases = { "garage" },
})
CampSite.RegisterRoomType("OFFICE", {
    label = "office",
    aliases = { "office", "study" },
})
CampSite.RegisterRoomType("LAUNDRY", {
    label = "laundry room",
    aliases = { "laundry", "laundry room", "laundryroom" },
})
CampSite.RegisterRoomType("STORAGE", {
    label = "storage room",
    aliases = { "storage", "storage room", "closet", "pantry" },
})
CampSite.RegisterRoomType("HALLWAY", {
    label = "hallway",
    aliases = { "hallway", "hall", "corridor" },
})

function CampSite.ResolveRoomType(value)
    local values = {}
    local key
    local candidate
    local roomID
    if type(value) == "table" then
        values = {
            value.roomType,
            value.room,
            value.concept,
            value.category,
            value.value,
            value.text,
            value.label,
            value.name,
        }
    else
        values[1] = value
    end
    for index = 1, #values do
        candidate = values[index]
        key = normalizeText(candidate)
        roomID = CampSite.RoomAliases[key]
            or CampSite.RoomAliases[compact(candidate)]
        if roomID then return roomID end
        roomID = roomTypeID(candidate)
        if CampSite.RoomTypes[roomID] then return roomID end

        -- RoomDef names commonly carry numeric suffixes (bedroom2) or omit
        -- the space (livingroom). Keep this fallback bounded and explicit.
        key = compact(candidate)
        if string.find(key, "bedroom", 1, true) then return "BEDROOM" end
        if string.find(key, "bathroom", 1, true)
            or string.find(key, "washroom", 1, true)
            or string.find(key, "restroom", 1, true)
        then
            return "BATHROOM"
        end
        if string.find(key, "livingroom", 1, true) then
            return "LIVING_ROOM"
        end
        if string.find(key, "diningroom", 1, true) then
            return "DINING_ROOM"
        end
        if string.find(key, "kitchen", 1, true) then return "KITCHEN" end
        if string.find(key, "garage", 1, true) then return "GARAGE" end
        if string.find(key, "office", 1, true)
            or string.find(key, "study", 1, true)
        then
            return "OFFICE"
        end
    end
    return nil
end

function CampSite.RoomTypesList()
    local output = {}
    for _, definition in pairs(CampSite.RoomTypes) do
        output[#output + 1] = definition
    end
    table.sort(output, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function CampSite.RoomLabel(roomType, roomName)
    local definition = CampSite.RoomTypes[roomTypeID(roomType)]
    local label = definition and definition.label or nil
    if label and label ~= "" then return label end
    -- RoomDef names are engine data, not player-facing taxonomy. An
    -- unclassified room must remain the generic semantic fallback instead of
    -- leaking names such as "other" or an arbitrary modded identifier.
    return "room"
end

function CampSite.NormalizeScope(value)
    value = string.lower(tostring(value or ""))
    if value == "inside" or value == "building" then return "room" end
    if value == "fire" or value == "firepit" then return "campfire" end
    if value == "here" or value == "room" or value == "campfire" then
        return value
    end
    return nil
end

function CampSite.NormalizeBounds(value)
    if type(value) ~= "table" then return nil end
    local minX = tonumber(value.minX or value.x)
    local minY = tonumber(value.minY or value.y)
    local maxX = tonumber(value.maxX or value.x2)
    local maxY = tonumber(value.maxY or value.y2)
    if not minX or not minY or not maxX or not maxY then return nil end
    return {
        minX = math.floor(math.min(minX, maxX)),
        minY = math.floor(math.min(minY, maxY)),
        maxX = math.floor(math.max(minX, maxX)),
        maxY = math.floor(math.max(minY, maxY)),
        z = tonumber(value.z),
    }
end

function CampSite.BoundsContain(bounds, x, y, z)
    bounds = CampSite.NormalizeBounds(bounds)
    x = tonumber(x)
    y = tonumber(y)
    if not bounds or x == nil or y == nil then return false end
    if x < bounds.minX or x > bounds.maxX
        or y < bounds.minY or y > bounds.maxY
    then
        return false
    end
    return bounds.z == nil or math.abs((tonumber(z) or 0) - bounds.z) <= 0.75
end

return CampSite
