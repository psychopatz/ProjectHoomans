-- Workshop catalog build orchestration provider.

PNC = PNC or {}
local Rebuild = PNC.WorkshopCatalogRebuild
local Internal = Rebuild.Internal or {}
Rebuild.Internal = Internal
local defaultStation = Internal.DefaultStation
local stationFor = Internal.StationFor
local hasStation = Internal.HasStation
local activeOrders = Internal.ActiveOrders
local rebuildQueue = Internal.RebuildQueue
local rebuildCraftRows = Internal.RebuildCraftRows
local rebuildSalvageRows = Internal.RebuildSalvageRows
local stationGroupKey = Internal.StationGroupKey
local skillGroupKey = Internal.SkillGroupKey
local productionSkillId = Internal.ProductionSkillId
local SearchIndex = require "PsychopatzCore/UI/PsychopatzSearchIndex"

local function rememberGroups(window, values, operation)
    for _, value in ipairs(values or {}) do
        local skillId = productionSkillId(value, operation)
        window.workshopKnownGroupKeys[skillGroupKey(operation, skillId)] = true
        window.workshopKnownGroupKeys[stationGroupKey(operation, skillId,
            Internal.StationFor(value, operation))] = true
    end
end

local function indexedEntries(window, indexKey, values, revision, fields)
    window[indexKey] = window[indexKey] or SearchIndex.New({
        fields = fields,
    })
    local index = window[indexKey]
    index:SetSource(values or {}, revision)
    local search = window.workshopSearch
        and window.workshopSearch:getText() or ""
    return index:Query(search)
end

function Rebuild.Build(window, snapshot, tr)
    if window.tab ~= "workshop" then return false end
    local workshop = snapshot.workshop or {}
    window.workshopKnownGroupKeys = {}
    local revision = window.lastReceiveRevision
        or snapshot.revision or workshop.revision
    local craftEntries = indexedEntries(window, "workshopCraftSearchIndex",
        workshop.knownRecipes, revision, function(recipe)
            local descriptor = recipe and recipe.descriptor or {}
            local station = stationFor(recipe, "CRAFT")
            return { descriptor.displayName, recipe and recipe.id,
                recipe and recipe.key, recipe and recipe.recipeKey,
                station and station.id, station and station.facilityId,
                station and station.labelKey }
        end)
    local salvageEntries = indexedEntries(window,
        "workshopSalvageSearchIndex", workshop.disassemblyCandidates,
        revision, function(candidate)
            return { candidate and candidate.fullType,
                candidate and candidate.name, candidate and candidate.recordIndex }
        end)
    local stationAvailability = {}
    local function isStationReady(station)
        -- AnySurfaceCraft and InHandCraft recipes intentionally have no
        -- workstation and are ready from a station perspective.
        if not station then return true end
        local id = tostring(station and station.id or "workshop")
        if stationAvailability[id] == nil then
            stationAvailability[id] = hasStation(snapshot, station)
        end
        return stationAvailability[id]
    end
    local sharedStation = defaultStation()
    local stationReady = sharedStation ~= nil
        and isStationReady(sharedStation) or false
    local function anyKnownStationReady(values, operation)
        if stationReady then return true end
        for _, value in ipairs(values or {}) do
            if isStationReady(stationFor(value, operation)) then return true end
        end
        return false
    end
    local craftStationReady = anyKnownStationReady(workshop.knownRecipes, "CRAFT")
    local salvageStationReady = anyKnownStationReady(
        workshop.disassemblyCandidates, "DISASSEMBLE")
    rememberGroups(window, workshop.knownRecipes, "CRAFT")
    rememberGroups(window, workshop.disassemblyCandidates, "DISASSEMBLE")
    -- A lane remains selectable when it has catalog entries even if its
    -- station is missing. The rows then expose BUILD STATION, so hiding or
    -- disabling the lane would hide the recovery path from the player.
    window.workshopLaneSelectable = {
        craft = #(workshop.knownRecipes or {}) > 0,
        salvage = #(workshop.disassemblyCandidates or {}) > 0,
    }
    window.workshopLaneAvailability = {
        -- Crafting and salvaging are different work types. They can use
        -- different direct workstation definitions, while each recipe still
        -- resolves to the same physical station for both operations.
        craft = craftStationReady,
        salvage = salvageStationReady,
    }
    rebuildQueue(window, activeOrders(snapshot))
    rebuildCraftRows(window, craftEntries, tr, isStationReady)
    rebuildSalvageRows(window, salvageEntries, tr, isStationReady)
    Rebuild.ApplySubtab(window, true)
    return true
end


return Rebuild
