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

function Rebuild.Build(window, snapshot, tr)
    if window.tab ~= "workshop" then return false end
    local workshop = snapshot.workshop or {}
    local stationAvailability = {}
    local function isStationReady(station)
        local id = tostring(station and station.id or "workshop")
        if stationAvailability[id] == nil then
            stationAvailability[id] = hasStation(snapshot, station)
        end
        return stationAvailability[id]
    end
    local sharedStation = defaultStation()
    local stationReady = isStationReady(sharedStation)
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
    window.workshopLaneAvailability = {
        -- Crafting and salvaging are different work types. They can use
        -- different direct workstation definitions, while each recipe still
        -- resolves to the same physical station for both operations.
        craft = craftStationReady,
        salvage = salvageStationReady,
    }
    rebuildQueue(window, activeOrders(snapshot))
    rebuildCraftRows(window, workshop.knownRecipes, tr, isStationReady)
    rebuildSalvageRows(window, workshop.disassemblyCandidates, tr, isStationReady)
    Rebuild.ApplySubtab(window, true)
    return true
end


return Rebuild
