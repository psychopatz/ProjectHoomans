PNC = PNC or {}
PNC.CharacterWindowShared = PNC.CharacterWindowShared or {}

local Shared = PNC.CharacterWindowShared

local itemStatsCache = {}

local function safeCall(target, methodName, ...)
    local method = target and target[methodName] or nil
    if type(method) ~= "function" then return nil end
    local ok, value = pcall(method, target, ...)
    return ok and value or nil
end

local function createItem(fullType)
    if PNC.Equipment and PNC.Equipment.CreateItem then
        local item = PNC.Equipment.CreateItem(fullType)
        if type(item) == "table" and item[1] then item = item[1] end
        if item then return item end
    end
    if instanceItem then
        local ok, item = pcall(instanceItem, fullType)
        if ok and item then return item end
    end
    return nil
end

local function round(value, digits)
    local multiplier = 10 ^ (tonumber(digits) or 0)
    return math.floor((tonumber(value) or 0) * multiplier + 0.5) / multiplier
end

function Shared.Round(value, digits)
    return round(value, digits)
end

function Shared.Clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function Shared.Text(key, fallback)
    if getText then
        local ok, value = pcall(getText, key)
        if ok and value and value ~= "" and value ~= key then return value end
    end
    return fallback or key
end

function Shared.GetSnapshot(snapshot, payload)
    return payload and payload.snapshot or snapshot or {}
end

function Shared.GetCharacterData(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    return resolved.characterWindow or snapshot and snapshot.characterWindow or {}
end

function Shared.GetIdentity(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    return payload and payload.identity or resolved.identity or {}
end

function Shared.GetEquipment(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    return payload and payload.equipment or resolved.equipmentSummary or {}
end

function Shared.GetCarry(snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    return payload and payload.inventory and payload.inventory.summary or resolved.inventorySummary or {}
end

function Shared.GetLiveCharacter(npcId)
    local key = npcId and tostring(npcId) or nil
    local sync = PNC.ClientPresenceSync
    local character = key and sync and sync.BodyByID and sync.BodyByID[key] or nil
    local function isUsable(candidate)
        if not candidate then return false end
        if not candidate.isDead then return true end
        local ok, dead = pcall(candidate.isDead, candidate)
        return ok and dead ~= true
    end
    if isUsable(character) then return character end
    if PNC.Registry and PNC.Registry.GetLiveZombie then
        character = PNC.Registry.GetLiveZombie(key)
        if isUsable(character) then return character end
    end
    return nil
end

function Shared.BuildPortraitSpec(npcId, snapshot, payload)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    return {
        id = npcId or resolved.id,
        key = table.concat({
            tostring(npcId or resolved.id or ""),
            tostring(resolved.identitySeed or 1),
            tostring(resolved.presenceRevision or 0),
        }, "|"),
        identitySeed = resolved.identitySeed or 1,
        isFemale = resolved.isFemale == true,
        outfit = resolved.appearance and resolved.appearance.outfit or nil,
        appearance = resolved.appearance or {},
        equipment = Shared.GetEquipment(snapshot, payload),
    }
end

local function itemStats(fullType)
    local cached = itemStatsCache[fullType]
    local item
    if cached then return cached end
    item = createItem(fullType)
    cached = {
        fullType = fullType,
        name = item and (safeCall(item, "getDisplayName") or safeCall(item, "getName")) or tostring(fullType),
        bite = tonumber(item and safeCall(item, "getBiteDefense")) or 0,
        scratch = tonumber(item and safeCall(item, "getScratchDefense")) or 0,
        insulation = tonumber(item and safeCall(item, "getInsulation")) or 0,
        wind = tonumber(item and safeCall(item, "getWindresist")) or 0,
    }
    itemStatsCache[fullType] = cached
    return cached
end

function Shared.BuildClothingRows(snapshot, payload)
    local equipment = Shared.GetEquipment(snapshot, payload)
    local rows = {}
    local location
    local fullType
    local stats
    for location, fullType in pairs(type(equipment.worn) == "table" and equipment.worn or {}) do
        stats = itemStats(fullType)
        rows[#rows + 1] = {
            location = tostring(location),
            fullType = fullType,
            name = stats.name,
            bite = stats.bite,
            scratch = stats.scratch,
            insulation = stats.insulation,
            wind = stats.wind,
        }
    end
    table.sort(rows, function(left, right)
        if left.location ~= right.location then return left.location < right.location end
        return tostring(left.fullType) < tostring(right.fullType)
    end)
    return rows
end

function Shared.SummarizeClothing(rows)
    local summary = { bite = 0, scratch = 0, insulation = 0, wind = 0, count = 0 }
    local i
    for i = 1, #(rows or {}) do
        summary.count = summary.count + 1
        summary.bite = summary.bite + (tonumber(rows[i].bite) or 0)
        summary.scratch = summary.scratch + (tonumber(rows[i].scratch) or 0)
        summary.insulation = summary.insulation + (tonumber(rows[i].insulation) or 0)
        summary.wind = summary.wind + (tonumber(rows[i].wind) or 0)
    end
    if summary.count > 0 then
        summary.biteAverage = summary.bite / summary.count
        summary.scratchAverage = summary.scratch / summary.count
        summary.insulationAverage = summary.insulation / summary.count
        summary.windAverage = summary.wind / summary.count
    else
        summary.biteAverage = 0
        summary.scratchAverage = 0
        summary.insulationAverage = 0
        summary.windAverage = 0
    end
    return summary
end

function Shared.GetThermalState(npcId)
    local character = Shared.GetLiveCharacter(npcId)
    local bodyDamage = character and safeCall(character, "getBodyDamage") or nil
    local thermoregulator = bodyDamage and safeCall(bodyDamage, "getThermoregulator") or nil
    if not thermoregulator then return nil end
    return {
        coreTemperature = tonumber(safeCall(thermoregulator, "getCoreTemperature")),
        coreTemperatureUI = tonumber(safeCall(thermoregulator, "getCoreTemperatureUI")),
        heatGenerationUI = tonumber(safeCall(thermoregulator, "getHeatGenerationUI")),
    }
end

function Shared.DrawSection(panel, title, x, y, width)
    panel:drawText(tostring(title), x, y, 1, 1, 1, 1, UIFont.Medium)
    local lineY = y + (getTextManager and getTextManager():getFontHeight(UIFont.Medium) or 18) + 2
    panel:drawRect(x, lineY, width, 1, 0.6, 0.4, 0.4, 0.4)
    return lineY + 8
end

function Shared.DrawLabelValue(panel, label, value, x, y, labelWidth, valueAlpha)
    panel:drawTextRight(tostring(label), x + labelWidth, y, 1, 1, 1, 1, UIFont.Small)
    panel:drawText(tostring(value), x + labelWidth + 10, y, 1, 1, 1, valueAlpha or 0.62, UIFont.Small)
    return y + (getTextManager and getTextManager():getFontHeight(UIFont.Small) or 14) + 6
end

function Shared.DrawBar(panel, label, value, maximum, x, y, width, color)
    local fontHeight = getTextManager and getTextManager():getFontHeight(UIFont.Small) or 14
    local ratio = Shared.Clamp((tonumber(value) or 0) / math.max(0.0001, tonumber(maximum) or 1), 0, 1)
    color = color or { r = 0.72, g = 0.72, b = 0.72 }
    panel:drawText(tostring(label), x, y, 1, 1, 1, 1, UIFont.Small)
    panel:drawTextRight(tostring(round(value, 1)) .. "/" .. tostring(round(maximum, 1)), x + width, y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    y = y + fontHeight + 3
    panel:drawRect(x, y, width, 10, 0.85, 0.08, 0.08, 0.08)
    panel:drawRect(x + 1, y + 1, math.max(0, (width - 2) * ratio), 8, 0.9, color.r, color.g, color.b)
    panel:drawRectBorder(x, y, width, 10, 0.85, 0.45, 0.45, 0.45)
    return y + 18
end

return Shared
