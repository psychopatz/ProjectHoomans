local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Support = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"

PNC = PNC or {}

local FishingActions = {}

local OFFSETS = {
    { x = -1, y = 0 }, { x = 1, y = 0 },
    { x = 0, y = -1 }, { x = 0, y = 1 },
    { x = -1, y = -1 }, { x = 1, y = -1 },
    { x = -1, y = 1 }, { x = 1, y = 1 },
}

local function worldCell()
    if _G and type(_G.getCell) == "function" then
        local ok, cell = pcall(_G.getCell)
        if ok then return cell end
    end
    return nil
end

local function squareIsWater(square)
    local result
    if not square then return false end
    if square.water == true then return true end
    if type(square.isWater) == "function" then
        local ok, result = pcall(square.isWater, square)
        if ok and result == true then return true end
    end
    if type(square.getProperties) == "function"
        and IsoFlagType and IsoFlagType.water
    then
        local ok, properties = pcall(square.getProperties, square)
        if ok and properties and type(properties.has) == "function" then
            ok, result = pcall(properties.has, properties, IsoFlagType.water)
            if ok and result == true then return true end
        end
    end
    return false
end

local function squareIsWalkableLand(square)
    if not square or squareIsWater(square) then return false end
    if square.walkable == false or square.solid == true then return false end
    if type(square.isFree) == "function" then
        local ok, result = pcall(square.isFree, square, true)
        if ok and result == false then return false end
    end
    return true
end

local function tileKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function inspectRegion(region)
    local bounds = GridRegion.bounds(region)
    local cell = worldCell()
    local water, lands = {}, {}
    local result = {
        waterCount = 0, landCount = 0, shorelineCount = 0,
        unloadedTiles = 0,
    }
    if not bounds or not cell or type(cell.getGridSquare) ~= "function" then
        result.unloadedTiles = 1
        return result
    end
    for z, level in pairs(region and region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            for index = 1, #spans, 2 do
                for x = spans[index], spans[index + 1] do
                    local ok, square = pcall(cell.getGridSquare, cell, x, y, z)
                    if not ok or not square then
                        result.unloadedTiles = result.unloadedTiles + 1
                    elseif squareIsWater(square) then
                        water[tileKey(x, y, z)] = true
                        result.waterCount = result.waterCount + 1
                    else
                        result.landCount = result.landCount + 1
                        if squareIsWalkableLand(square) then
                            lands[#lands + 1] = { x = x, y = y, z = z }
                        end
                    end
                end
            end
        end
    end
    for _, land in ipairs(lands) do
        for _, offset in ipairs(OFFSETS) do
            if water[tileKey(land.x + offset.x, land.y + offset.y, land.z)] then
                result.shorelineCount = result.shorelineCount + 1
                break
            end
        end
    end
    return result
end

local function setSelectionColor(selector, valid)
    if not selector then return end
    selector.highlightColor = valid
        and { r = 0.18, g = 1.00, b = 0.38, a = 0.42 }
        or { r = 1.00, g = 0.18, b = 0.12, a = 0.48 }
    selector.previewColor = valid
        and { r = 0.30, g = 1.00, b = 0.45, a = 0.28 }
        or { r = 1.00, g = 0.30, b = 0.20, a = 0.30 }
end

local function selectionTarget(region)
    local bounds = GridRegion.bounds(region)
    if not bounds then return nil end
    return {
        x = (bounds.minX + bounds.maxX) / 2 + 0.5,
        y = (bounds.minY + bounds.maxY) / 2 + 0.5,
        z = bounds.minZ,
    }
end

local function validation(region, stats, selector)
    local valid, reason = Support.ValidateConnected(region)
    local preview = inspectRegion(region)
    local reasonKey, fallback
    if not valid then
        reasonKey, fallback = "UI_PNC_Fishing_InvalidConnected",
            "Selection must be one connected area."
    elseif preview.unloadedTiles > 0 then
        valid = false
        reasonKey, fallback = "UI_PNC_Fishing_Unloaded",
            "Some selected tiles are not loaded."
    elseif preview.waterCount <= 0 then
        valid = false
        reasonKey, fallback = "UI_PNC_Fishing_NoWater",
            "Selection must include water."
    elseif preview.landCount <= 0 then
        valid = false
        reasonKey, fallback = "UI_PNC_Fishing_NoLand",
            "Selection must include land."
    elseif preview.shorelineCount <= 0 then
        valid = false
        reasonKey, fallback = "UI_PNC_Fishing_NoShoreline",
            "No walkable land tile touches the selected water."
    end
    setSelectionColor(selector, valid == true)
    if not valid then
        reason = Support.Tr(reasonKey, fallback)
    end
    stats.fishingWaterCount = preview.waterCount
    stats.fishingLandCount = preview.landCount
    stats.fishingShorelineCount = preview.shorelineCount
    return valid == true, reason, {
        fishingWaterCount = preview.waterCount,
        fishingLandCount = preview.landCount,
        fishingShorelineCount = preview.shorelineCount,
    }
end

function FishingActions.BeginForSelection(window, people)
    local settlement = window and window.snapshot
        and window.snapshot.settlement or nil
    local npcIds = {}
    for _, person in ipairs(people or {}) do
        local id = tostring(person and (person.id or person.npcId) or "")
        if id ~= "" then npcIds[#npcIds + 1] = id end
    end
    if #npcIds <= 0 then
        local id = tostring(window and window.selectedPersonID or "")
        if id ~= "" then npcIds[1] = id end
    end
    if #npcIds <= 0 then return false, "FISHING_NPC_REQUIRED" end

    local selectorOptions = {
        title = Support.Tr("UI_PNC_Fishing_SelectTitle",
            "SELECT FISHING AREA"),
        instruction = Support.Tr("UI_PNC_Fishing_SelectHelp",
            "Select connected land and water; shoreline land becomes fishing spots."),
        initialRegion = Support.EmptyRegion(),
        guideRegion = settlement.geometry and settlement.geometry.region or nil,
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
        maxTiles = tonumber(PNC.Const and PNC.Const.FISHING_MAX_ZONE_TILES)
            or 10000,
        highlightColor = { r = 1.00, g = 0.18, b = 0.12, a = 0.48 },
        previewColor = { r = 1.00, g = 0.30, b = 0.20, a = 0.30 },
    }
    selectorOptions.validate = validation
    selectorOptions.onConfirm = function(region)
        local target = selectionTarget(region)
        if not target or not PNC.Client
            or type(PNC.Client.SendMapCommand) ~= "function"
        then return end
        local sent, result = PNC.Client.SendMapCommand("fishing_zone",
            npcIds, target, { region = region })
        if sent and result and result.ok == true
            and PNC.FishingZoneOverlay
            and PNC.FishingZoneOverlay.SetZone
        then
            PNC.FishingZoneOverlay.SetZone(result.details)
        end
        Support.ApplyLocalResult(window)
    end
    local selector, reason = Support.OpenSelector(window, selectorOptions)
    if not selector then return false, reason or "SELECTOR_UNAVAILABLE" end
    return true
end

function FishingActions.Begin(window)
    return FishingActions.BeginForSelection(window, nil)
end

FishingActions.ValidateRegion = validation

return FishingActions
