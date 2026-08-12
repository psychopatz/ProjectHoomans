local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Support = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"

local Facility = {}

local function areaRole(facility)
    if not facility then return nil end
    if facility.definitionId == "barracks" then return "sleep.area" end
    if facility.definitionId == "farm" then return "farm.field" end
    return nil
end

function Facility.BeginArea(window, facility)
    local role = areaRole(facility)
    if not role then return false end
    local existing = Support.ComponentForRole(facility, role)
    local level = PNC.FacilityDefinitions.GetLevel(facility.definitionId, facility.level)
    local limit = level and level.componentLimits[role] or {}
    Support.OpenSelector(window, {
        title = Support.Tr("UI_PNC_Facility_SelectArea", "SELECT FACILITY AREA"),
        instruction = role == "farm.field"
            and Support.Tr("UI_PNC_Facility_SelectFarmlandHelp",
                "Select connected cultivated farmland inside the base.")
            or Support.Tr("UI_PNC_Facility_SelectAreaHelp",
                "Select one connected area inside the base territory."),
        initialRegion = existing and existing.region or Support.EmptyRegion(),
        guideRegion = Support.BaseRegion(window),
        guideLayers = Support.UsedGuideLayers(window, existing and existing.id),
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
        maxTiles = limit.maxTotalTiles,
        requiredSquareRule = limit.worldRule,
        validate = function(region, stats)
            local ok, reason = Support.ValidateConnected(region)
            if ok and not GridRegion.containsRegion(
                Support.BaseRegion(window), Support.Footprint(region))
            then ok, reason = false, "OUTSIDE_BASE" end
            if ok and limit.maxTotalTiles and stats.tileCount > limit.maxTotalTiles then
                ok, reason = false, "FACILITY_AREA_TOO_LARGE"
            end
            return ok, ok and nil or Shared.SettlementReason(reason)
        end,
        onConfirm = function(region)
            PNC.Client.RequestSetFacilityComponent({ facilityId = facility.id,
                expectedRevision = facility.revision,
                component = { id = existing and existing.id or nil,
                    kind = "region", role = role, region = region } })
            Support.ApplyLocalResult(window)
        end,
    })
    return true
end

function Facility.BeginPoint(window, kind, facility)
    local bed = kind == "bed"
    Support.OpenSelector(window, {
        title = bed and Support.Tr("UI_PNC_Facility_SelectBed", "SELECT BED")
            or Support.Tr("UI_PNC_Stockpile_SelectNode", "SELECT STOCKPILE ACCESS TILE"),
        instruction = bed and Support.Tr("UI_PNC_Facility_SelectBedHelp",
            "Choose a sleeping spot. A bed is used automatically when present; otherwise the colonist sleeps on the floor.")
            or Support.Tr("UI_PNC_Point_SelectHelp", "Click one tile, then confirm."),
        selectionKind = "point",
        guideRegion = Support.BaseRegion(window),
        guideLayers = Support.UsedGuideLayers(window),
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
        validate = function(region)
            local bounds = GridRegion.bounds(region)
            if not bounds or not GridRegion.containsXY(
                Support.BaseRegion(window), bounds.minX, bounds.minY)
            then return false, Shared.SettlementReason("OUTSIDE_BASE") end
            return true
        end,
        onConfirm = function(region)
            local bounds = GridRegion.bounds(region)
            if bed then
                PNC.Client.RequestSetFacilityComponent({ facilityId = facility.id,
                    expectedRevision = facility.revision,
                    component = { kind = "anchor", role = "sleep.bed",
                        x = bounds.minX, y = bounds.minY, z = bounds.minZ,
                        targetResolver = "sleepSpot" } })
            else
                local settlement = window.snapshot.settlement
                local storage = window.snapshot.storage or {}
                PNC.Client.RequestCreateStockpileAccessNode({ baseId = settlement.id,
                    expectedRevision = settlement.revision,
                    storageId = storage.storageId, x = bounds.minX,
                    y = bounds.minY, z = bounds.minZ })
            end
            Support.ApplyLocalResult(window)
        end,
    })
end

return Facility
