PNC = PNC or {}
PNC.FacilityDefinitions = PNC.FacilityDefinitions or {}

local Definitions = PNC.FacilityDefinitions
local Policy = PNC.FacilityComponentPolicy
    or require "PNC/Core/Settlement/PNC_FacilityComponentPolicy"

Definitions.SCHEMA_VERSION = 1
Definitions.ByID = Definitions.ByID or {}

Definitions.ComponentIconPaths = Definitions.ComponentIconPaths or {
    ["storage.stockpile"] = "media/ui/Facilities/Components/storage/stockpile.png",
    ["sleep.area"] = "media/ui/Facilities/Components/chair.png",
    ["sleep.bed"] = "media/ui/Facilities/Components/bed/barracks.png",
    ["living.room"] = "media/ui/Facilities/Components/chair.png",
    ["living.chair"] = "media/ui/Facilities/Components/chair.png",
    ["dining.table"] = "media/ui/Facilities/Components/chair.png",
    ["health.bed"] = "media/ui/Facilities/Components/bed/hospital.png",
    ["growing.plot"] = "media/ui/Facilities/Components/default.png",
    -- All research lanes share one physical native Log Table.
    ["work.research"] = "media/ui/Facilities/Components/workshop/workbench.png",
    ["work.blueprint"] = "media/ui/Facilities/Components/workshop/workbench.png",
    ["work.reverse"] = "media/ui/Facilities/Components/workshop/workbench.png",
    ["work.craft"] = "media/ui/Facilities/Components/workshop/workbench.png",
    ["work.disassemble"] = "media/ui/Facilities/Components/workshop/recycling_bench.png",
    ["work.zone"] = "media/ui/Facilities/Components/workshop/workbench.png",
    ["water.spigot"] = "media/ui/Facilities/Components/water_station/pump_spigot.png",
    ["water.tank"] = "media/ui/Facilities/Components/default.png",
    ["water.catcher"] = "media/ui/Facilities/Components/default.png",
}

function Definitions.GetComponentIconPath(role)
    return Definitions.ComponentIconPaths[tostring(role or "")]
        or "media/ui/Facilities/Components/default.png"
end

function Definitions.Register(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string"
        or definition.id == "" or type(definition.levels) ~= "table"
    then
        return false, "INVALID_FACILITY_DEFINITION"
    end
    -- Every facility owns one editable labor spot. Keep this in the shared
    -- registration path so new definitions cannot accidentally omit it.
    for _, level in pairs(definition.levels) do
        level.componentLimits = level.componentLimits or {}
        if not level.componentLimits["work.zone"] then
            level.componentLimits["work.zone"] = {
                kind = "region", minCount = 1, maxCount = 1,
                minTotalTiles = 1, maxTotalTiles = 1, workZone = true,
            }
        end
    end
    Definitions.ByID[definition.id] = definition
    return true, definition
end

function Definitions.Get(id)
    return Definitions.ByID[tostring(id or "")]
end

function Definitions.GetLevel(id, level)
    local definition = Definitions.Get(id)
    return definition and definition.levels[math.floor(tonumber(level) or 1)] or nil
end

function Definitions.GetComponentCosts(id, level, role)
    local definition = Definitions.Get(id)
    local levelData = Definitions.GetLevel(id, level)
    return Policy.GetCosts(definition, levelData, role)
end

function Definitions.GetComponentBuildWork(id, level, role)
    local definition = Definitions.Get(id)
    local levelData = Definitions.GetLevel(id, level)
    return Policy.GetBuildWork(definition, levelData, role)
end

function Definitions.RequiresComponentConstruction(id, level, role, kind)
    local definition = Definitions.Get(id)
    local levelData = Definitions.GetLevel(id, level)
    return Policy.RequiresConstruction(definition, levelData, role, kind)
end

function Definitions.GetComponentLimit(id, level, role)
    local levelData = Definitions.GetLevel(id, level)
    local limit = levelData and levelData.componentLimits
        and levelData.componentLimits[tostring(role or "")] or nil
    if not limit then return nil end
    -- Anchors occupy one selected tile unless a definition explicitly models a
    -- multi-tile world object (beds are the first such special case).
    if limit.kind == "anchor" and limit.fixedTileCount == nil then
        limit.fixedTileCount = 1
    end
    return limit
end

return Definitions
