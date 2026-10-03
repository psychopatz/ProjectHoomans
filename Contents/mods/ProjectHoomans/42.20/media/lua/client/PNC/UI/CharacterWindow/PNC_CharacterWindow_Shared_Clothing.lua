PNC = PNC or {}
PNC.CharacterWindowShared = PNC.CharacterWindowShared or {}

local Shared = PNC.CharacterWindowShared

local Internal = Shared.Internal
local safeCall = Internal.safeCall
local createItem = Internal.createItem
local coveredParts = Internal.coveredParts
local virtualWornItem = Internal.virtualWornItem
local liveWornItem = Internal.liveWornItem
local applyVirtualState = Internal.applyVirtualState
local itemStatsCache = Internal.itemStatsCache

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
    local inventory = payload and payload.inventory or nil
    local character = Shared.GetLiveCharacter(npcId or Shared.GetSnapshot(snapshot, payload).id)
    local rows = {}
    local location
    local fullType
    local stats
    if inventory and type(inventory.worn) == "table"
        and type(inventory.items) == "table"
    then
        equipment = { worn = {} }
        for location, itemId in pairs(inventory.worn) do
            local state = inventory.items[itemId]
            if state and state.type then equipment.worn[location] = state.type end
        end
    end
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
    local hasAuthoritativeInventory = payload
        and payload.inventory
        and type(payload.inventory.worn) == "table"
        and type(payload.inventory.items) == "table"
    local output = {}
    local biteTotal = 0
    local scratchTotal = 0
    for _, definition in ipairs(Shared.BodyParts) do
        local bite = not hasAuthoritativeInventory
            and bodyDefense(character, definition.index, true) or nil
        local scratch = not hasAuthoritativeInventory
            and bodyDefense(character, definition.index, false) or nil
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

return Shared
