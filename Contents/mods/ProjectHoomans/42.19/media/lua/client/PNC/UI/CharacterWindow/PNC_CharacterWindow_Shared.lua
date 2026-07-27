PNC = PNC or {}
PNC.CharacterWindowShared = PNC.CharacterWindowShared or {}

local Shared = PNC.CharacterWindowShared

local itemStatsCache = {}
local bodyTextureCache = {}

Shared.BodyParts = {
    { id = "Hand_L", index = 0, label = "Left Hand", texture = "left-hand" },
    { id = "Hand_R", index = 1, label = "Right Hand", texture = "right-hand" },
    { id = "ForeArm_L", index = 2, label = "Left Forearm", texture = "lower-left-arm" },
    { id = "ForeArm_R", index = 3, label = "Right Forearm", texture = "lower-right-arm" },
    { id = "UpperArm_L", index = 4, label = "Left Upper Arm", texture = "upper-left-arm", maleNodeX = 10, femaleNodeX = 4 },
    { id = "UpperArm_R", index = 5, label = "Right Upper Arm", texture = "upper-right-arm", maleNodeX = -10, femaleNodeX = -4 },
    { id = "Torso_Upper", index = 6, label = "Upper Torso", texture = "chest" },
    { id = "Torso_Lower", index = 7, label = "Lower Torso", texture = "abdomen" },
    { id = "Head", index = 8, label = "Head", texture = "head" },
    { id = "Neck", index = 9, label = "Neck", texture = "neck" },
    { id = "Groin", index = 10, label = "Groin", texture = "groin" },
    { id = "UpperLeg_L", index = 11, label = "Left Thigh", texture = "left-thigh", nodeX = -2, nodeY = 10 },
    { id = "UpperLeg_R", index = 12, label = "Right Thigh", texture = "right-thigh", nodeX = 2, nodeY = 10 },
    { id = "LowerLeg_L", index = 13, label = "Left Shin", texture = "left-calf" },
    { id = "LowerLeg_R", index = 14, label = "Right Shin", texture = "right-calf" },
    { id = "Foot_L", index = 15, label = "Left Foot", texture = "left-foot", nodeX = -2 },
    { id = "Foot_R", index = 16, label = "Right Foot", texture = "right-foot", nodeX = 2 },
}

local BODY_PART_BY_ID = {}
for _, definition in ipairs(Shared.BodyParts) do
    BODY_PART_BY_ID[definition.id] = definition
end

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

local function listSize(list)
    return list and list.size and tonumber(list:size()) or 0
end

local function listGet(list, index)
    return list and list.get and list:get(index) or nil
end

local function normalizePartId(value)
    local name = value and tostring(value) or ""
    name = string.match(name, "([%w_]+)$") or name
    return BODY_PART_BY_ID[name] and name or nil
end

local function markCoverage(output, partId)
    if partId and BODY_PART_BY_ID[partId] then output[partId] = true end
end

local function fallbackCoverage(location)
    local output = {}
    local slot = string.lower(tostring(location or ""))
    if string.find(slot, "hat", 1, true) or string.find(slot, "head", 1, true) then
        output.Head = true
    end
    if string.find(slot, "neck", 1, true) or string.find(slot, "scarf", 1, true) then
        output.Neck = true
    end
    if string.find(slot, "hand", 1, true) or string.find(slot, "glove", 1, true) then
        output.Hand_L = true
        output.Hand_R = true
    end
    if string.find(slot, "shoe", 1, true) or string.find(slot, "sock", 1, true) or string.find(slot, "foot", 1, true) then
        output.Foot_L = true
        output.Foot_R = true
    end
    if string.find(slot, "pants", 1, true) or string.find(slot, "trouser", 1, true)
        or string.find(slot, "skirt", 1, true) or string.find(slot, "short", 1, true)
    then
        output.Torso_Lower = true
        output.Groin = true
        output.UpperLeg_L = true
        output.UpperLeg_R = true
        output.LowerLeg_L = true
        output.LowerLeg_R = true
    end
    if string.find(slot, "shirt", 1, true) or string.find(slot, "jacket", 1, true)
        or string.find(slot, "sweater", 1, true) or string.find(slot, "top", 1, true)
        or string.find(slot, "torso", 1, true) or string.find(slot, "suit", 1, true)
    then
        output.Torso_Upper = true
        output.Torso_Lower = true
        output.UpperArm_L = true
        output.UpperArm_R = true
        output.ForeArm_L = true
        output.ForeArm_R = true
    end
    return output
end

local function coveredParts(item, location)
    local output = {}
    local covered = safeCall(item, "getCoveredParts")
    local size = listSize(covered)
    local i
    if size <= 0 then return fallbackCoverage(location) end
    for i = 0, size - 1 do
        markCoverage(output, normalizePartId(listGet(covered, i)))
    end
    return output
end

local function virtualWornItem(payload, location)
    local inventory = payload and payload.inventory or nil
    local itemId = inventory and inventory.worn and inventory.worn[location] or nil
    return itemId and inventory.items and inventory.items[itemId] or nil
end

local function liveWornItem(character, location)
    local worn = character and safeCall(character, "getWornItems") or nil
    local i
    -- Build 42 WornItems:getItem() accepts ItemBodyLocation, not the legacy
    -- string body-location names stored in the PNC record. Iteration works for
    -- both legacy string locations and the new typed locations without asking
    -- Kahlua to select an invalid Java overload.
    for i = 0, listSize(worn) - 1 do
        local entry = listGet(worn, i)
        local entryLocation = entry and (safeCall(entry, "getLocation") or safeCall(entry, "getBodyLocation")) or nil
        if tostring(entryLocation or "") == tostring(location) then
            return safeCall(entry, "getItem") or entry
        end
    end
    return nil
end

local function applyVirtualState(item, state)
    local maximum
    if not item or type(state) ~= "table" then return item end
    maximum = tonumber(safeCall(item, "getConditionMax")) or 0
    if state.cond ~= nil and item.setCondition then
        pcall(item.setCondition, item, math.max(0, math.min(maximum > 0 and maximum or tonumber(state.cond), tonumber(state.cond) or 0)))
    end
    if state.uses ~= nil and item.setUses then
        pcall(item.setUses, item, math.max(0, tonumber(state.uses) or 0))
    end
    return item
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
        preferDescriptor = true,
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

function Shared.BuildClothingRows(snapshot, payload, npcId)
    local equipment = Shared.GetEquipment(snapshot, payload)
    local character = Shared.GetLiveCharacter(npcId or Shared.GetSnapshot(snapshot, payload).id)
    local rows = {}
    local location
    local fullType
    local stats
    for location, fullType in pairs(type(equipment.worn) == "table" and equipment.worn or {}) do
        stats = itemStats(fullType)
        local state = virtualWornItem(payload, location)
        local item = liveWornItem(character, location) or applyVirtualState(createItem(fullType), state)
        local conditionMax = tonumber(item and safeCall(item, "getConditionMax")) or 0
        local condition = tonumber(item and safeCall(item, "getCondition"))
            or tonumber(state and state.cond) or conditionMax
        local conditionRatio = conditionMax > 0 and Shared.Clamp(condition / conditionMax, 0, 1) or 1
        rows[#rows + 1] = {
            location = tostring(location),
            fullType = fullType,
            itemId = state and state.id or nil,
            item = item,
            name = item and (safeCall(item, "getDisplayName") or safeCall(item, "getName")) or stats.name,
            bite = tonumber(item and safeCall(item, "getBiteDefense")) or stats.bite,
            scratch = tonumber(item and safeCall(item, "getScratchDefense")) or stats.scratch,
            insulation = tonumber(item and safeCall(item, "getInsulation")) or stats.insulation,
            wind = tonumber(item and (safeCall(item, "getWindresistance") or safeCall(item, "getWindresist"))) or stats.wind,
            condition = condition,
            conditionMax = conditionMax,
            conditionRatio = conditionRatio,
            uses = tonumber(state and state.uses) or tonumber(item and safeCall(item, "getUses")),
            wetness = tonumber(item and safeCall(item, "getWetness")) or 0,
            holes = tonumber(item and safeCall(item, "getHolesNumber")) or 0,
            coveredParts = coveredParts(item, location),
        }
    end
    table.sort(rows, function(left, right)
        if left.location ~= right.location then return left.location < right.location end
        return tostring(left.fullType) < tostring(right.fullType)
    end)
    return rows
end

local function bodyDefense(character, index, bite)
    local method = character and character.getBodyPartClothingDefense or nil
    local ok
    local value
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, character, index, bite == true, false)
    return ok and tonumber(value) or nil
end

function Shared.BuildBodyProtection(npcId, snapshot, payload, rows)
    rows = rows or Shared.BuildClothingRows(snapshot, payload, npcId)
    local character = Shared.GetLiveCharacter(npcId)
    local output = {}
    local biteTotal = 0
    local scratchTotal = 0
    for _, definition in ipairs(Shared.BodyParts) do
        local bite = bodyDefense(character, definition.index, true)
        local scratch = bodyDefense(character, definition.index, false)
        if bite == nil or scratch == nil then
            bite = 0
            scratch = 0
            for _, row in ipairs(rows) do
                if row.coveredParts and row.coveredParts[definition.id] then
                    bite = bite + (tonumber(row.bite) or 0) * (tonumber(row.conditionRatio) or 1)
                    scratch = scratch + (tonumber(row.scratch) or 0) * (tonumber(row.conditionRatio) or 1)
                end
            end
        end
        bite = Shared.Clamp(bite, 0, 100)
        scratch = Shared.Clamp(scratch, 0, 100)
        output[definition.id] = { bite = bite, scratch = scratch, value = Shared.Clamp(bite + scratch, 0, 100) }
        biteTotal = biteTotal + bite
        scratchTotal = scratchTotal + scratch
    end
    output.biteAverage = biteTotal / #Shared.BodyParts
    output.scratchAverage = scratchTotal / #Shared.BodyParts
    return output
end

function Shared.BuildBodyInsulation(npcId, snapshot, payload, rows)
    rows = rows or Shared.BuildClothingRows(snapshot, payload, npcId)
    local output = {}
    local insulationTotal = 0
    local windTotal = 0
    for _, definition in ipairs(Shared.BodyParts) do
        local insulation = 0
        local wind = 0
        for _, row in ipairs(rows) do
            if row.coveredParts and row.coveredParts[definition.id] then
                local condition = tonumber(row.conditionRatio) or 1
                local dry = 1 - Shared.Clamp((tonumber(row.wetness) or 0) / 100, 0, 1) * 0.65
                insulation = insulation + (tonumber(row.insulation) or 0) * condition * dry
                wind = wind + (tonumber(row.wind) or 0) * condition
            end
        end
        insulation = Shared.Clamp(insulation, 0, 1)
        wind = Shared.Clamp(wind, 0, 1)
        output[definition.id] = { insulation = insulation, wind = wind, value = insulation }
        insulationTotal = insulationTotal + insulation
        windTotal = windTotal + wind
    end
    output.insulationAverage = insulationTotal / #Shared.BodyParts
    output.windAverage = windTotal / #Shared.BodyParts
    return output
end

local function bodyTexture(path)
    local key = tostring(path)
    if bodyTextureCache[key] == nil then
        bodyTextureCache[key] = getTexture(path)
    end
    return bodyTextureCache[key]
end

function Shared.ProtectionColor(value)
    local ratio = Shared.Clamp((tonumber(value) or 0) / 100, 0, 1)
    return 0.9 - ratio * 0.62, 0.12 + ratio * 0.72, 0.1
end

function Shared.TemperatureColor(value)
    local ratio = Shared.Clamp(tonumber(value) or 0, 0, 1)
    if ratio < 0.5 then return 0.08, 0.35 + ratio, 1 - ratio * 0.7 end
    return 0.2 + ratio * 0.8, 1 - (ratio - 0.5) * 1.6, 0.12
end

function Shared.DrawBodyMap(view, isFemale, x, y, width, height, values, colorForValue)
    local sex = isFemale and "female" or "male"
    local base = bodyTexture("media/ui/BodyParts/" .. sex .. "_base_white")
    local outline = bodyTexture("media/ui/BodyParts/bps_" .. sex .. "_outlines")
    local originalWidth = base and (base.getWidthOrig and base:getWidthOrig() or base:getWidth()) or 123
    local originalHeight = base and (base.getHeightOrig and base:getHeightOrig() or base:getHeight()) or 302
    local scale = math.min(width / math.max(1, originalWidth), height / math.max(1, originalHeight))
    local drawWidth = originalWidth * scale
    local drawHeight = originalHeight * scale
    local drawX = x + (width - drawWidth) / 2
    local bounds = { x = drawX, y = y, width = drawWidth, height = drawHeight, scale = scale, parts = {} }
    if base then view:drawTextureScaled(base, drawX, y, drawWidth, drawHeight, 0.25, 1, 1, 1) end
    for _, definition in ipairs(Shared.BodyParts) do
        local entry = values and values[definition.id] or nil
        local value = type(entry) == "table" and entry.value or entry
        local texture = bodyTexture("media/ui/BodyParts/bps_" .. sex .. "_" .. definition.texture)
        if texture then
            local offsetX = texture.getOffsetX and texture:getOffsetX() or 0
            local offsetY = texture.getOffsetY and texture:getOffsetY() or 0
            local textureWidth = texture.getWidth and texture:getWidth() or 0
            local textureHeight = texture.getHeight and texture:getHeight() or 0
            local nodeX = tonumber(definition.nodeX) or 0
            local nodeY = tonumber(definition.nodeY) or 0
            if isFemale and definition.femaleNodeX then nodeX = definition.femaleNodeX end
            if not isFemale and definition.maleNodeX then nodeX = definition.maleNodeX end
            bounds.parts[definition.id] = {
                x = drawX + (offsetX + textureWidth / 2 + nodeX) * scale,
                y = y + (offsetY + textureHeight / 2 + nodeY) * scale,
            }
        end
        if value ~= nil then
            local r, g, b = 1, 1, 1
            if colorForValue then r, g, b = colorForValue(value) end
            if texture then
                local offsetX = texture.getOffsetX and texture:getOffsetX() or 0
                local offsetY = texture.getOffsetY and texture:getOffsetY() or 0
                local textureWidth = texture.getWidth and texture:getWidth() or 0
                local textureHeight = texture.getHeight and texture:getHeight() or 0
                view:drawTextureScaled(texture, drawX + offsetX * scale, y + offsetY * scale,
                    textureWidth * scale, textureHeight * scale, 0.8, r, g, b)
            end
        end
    end
    if outline then view:drawTextureScaled(outline, drawX, y, drawWidth, drawHeight, 1, 1, 1, 1) end
    return bounds
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
