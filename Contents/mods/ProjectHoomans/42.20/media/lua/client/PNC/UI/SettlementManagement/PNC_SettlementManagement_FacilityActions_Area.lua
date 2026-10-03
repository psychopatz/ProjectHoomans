local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Support = require "PNC/UI/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
local Facility = PNC.SettlementManagementFacilityActions
local Farming = PNC.Farming
local Internal = Facility.Internal

local function areaRole(facility)
    local level = facility and PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level or 1) or nil
    local roles = {}
    for role, limit in pairs(level and level.componentLimits or {}) do
        if limit.kind == "region" and role ~= "work.zone" then
            roles[#roles + 1] = role
        end
    end
    table.sort(roles)
    return roles[1]
end

Facility.AreaRole = areaRole

local function areaOptions(window, facility, existing, onConfirm, requestedRole)
    local isDraft = not facility or facility.id == nil
    local role = requestedRole or areaRole(facility)
    if isDraft and facility.definitionId == "farm" then
        role = "facility.footprint"
    end
    -- Construction always selects an abstract footprint. Legacy anchor-only
    -- facilities (utilities and future non-native workstation buildings) do
    -- not declare a functional region role, so their draft still needs this
    -- selector role.
    if not role and isDraft then role = "facility.footprint" end
    if not role then return nil end
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level or 1)
    local limit = level and level.componentLimits[role] or {}
    local movingStockpile = not isDraft
        and facility.definitionId == "stockpile"
        and role == "storage.stockpile"
    local boundary
    if role == "work.zone" then
        boundary = Support.WorkZoneRegion(facility)
    elseif isDraft or movingStockpile then
        boundary = Support.BaseRegion(window)
    else
        boundary = Support.FacilityRegion(facility)
    end
    return {
        title = Support.Tr("UI_PNC_Facility_SelectArea", "SELECT FACILITY AREA"),
        instruction = role == "facility.footprint"
            and Support.Tr("UI_PNC_Facility_SelectFootprintHelp",
                "Select the building footprint inside the base territory.")
            or role == "growing.plot"
            and Support.Tr("UI_PNC_Facility_SelectFarmlandHelp",
                "Select connected cultivated farmland inside the base.")
            or role == "work.zone"
            and Support.Tr("UI_PNC_Facility_SelectWorkZoneHelp",
                "Select one connected tile inside or beside the facility where workers stand.")
            or movingStockpile
            and Support.Tr("UI_PNC_Facility_SelectStockpileAreaHelp",
                "Select a connected stockpile area inside Base Zone territory.")
            or Support.Tr("UI_PNC_Facility_SelectAreaHelp",
                "Select one connected room inside the base territory."),
        initialRegion = existing and existing.region or Support.EmptyRegion(),
        guideRegion = boundary,
        guideLayers = Support.UsedGuideLayers(window, existing and existing.id),
        guideRenderZ = nil,
        guideColor = (isDraft or movingStockpile)
            and { r = 0.10, g = 0.70, b = 1.00, a = 0.24 } or nil,
        debugLabel = tostring(facility.definitionId or "facility")
            .. ":" .. tostring(role),
        selectionKind = role == "work.zone" and "point" or "region",
        maxTiles = limit.maxTotalTiles,
        requiredSquareRule = role == "growing.plot" and nil or limit.worldRule,
        validate = function(region, stats)
            local ok, reason = Support.ValidateConnected(region)
            if ok and boundary and not GridRegion.containsRegion(boundary, region) then
                ok, reason = false, (isDraft or movingStockpile) and "OUTSIDE_BASE"
                    or "OUTSIDE_FACILITY"
            end
            if ok and limit.maxTotalTiles and stats.tileCount > limit.maxTotalTiles then
                ok, reason = false, "FACILITY_AREA_TOO_LARGE"
            end
            if ok and role == "growing.plot" then
                local valid, plotReason = Farming.RectangleInfo(region)
                if not valid then ok, reason = false, plotReason end
                if ok then
                    local furrow = false
                    local farming = CFarmingSystem and CFarmingSystem.instance or nil
                    local bounds = GridRegion.bounds(region)
                    if not bounds then return false, "EMPTY_REGION" end
                    for y = bounds.minY, bounds.maxY do
                        for x = bounds.minX, bounds.maxX do
                            local square = getCell():getGridSquare(x, y, bounds.minZ)
                            local plant = square and farming and farming.getLuaObjectOnSquare
                                and farming:getLuaObjectOnSquare(square) or nil
                            if plant and tostring(plant.state or "") == "plow" then
                                furrow = true
                            end
                        end
                    end
                    if not furrow then ok, reason = false, "FARMING_FURROW_REQUIRED" end
                end
            end
            return ok, ok and nil or Shared.SettlementReason(reason)
        end,
        tileValidator = boundary and function(x, y, z)
            local inside
            if isDraft or movingStockpile then
                if GridRegion.containsXY then
                    inside = GridRegion.containsXY(boundary, x, y)
                else
                    inside = GridRegion.containsPoint(
                        boundary, x, y, z)
                end
            else
                inside = GridRegion.containsPoint(boundary, x, y, z)
            end
            if not inside then
                return false, Shared.SettlementReason(
                    (isDraft or movingStockpile)
                        and "OUTSIDE_BASE" or "OUTSIDE_FACILITY")
            end
            return true
        end or nil,
        onConfirm = onConfirm,
    }
end


Internal.AreaRole = areaRole
Internal.AreaOptions = areaOptions
