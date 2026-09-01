local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Support = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
local Placement = require "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacement"
local Farming = PNC.Farming

local Facility = {}

local ANCHOR_LABELS = {
    ["sleep.bed"] = "UI_PNC_Facility_SleepSpot",
    ["work.research"] = "UI_PNC_Facility_ResearchTable",
    ["work.blueprint"] = "UI_PNC_Facility_ResearchTable",
    ["work.reverse"] = "UI_PNC_Facility_ResearchTable",
    ["work.craft"] = "UI_PNC_Facility_CraftingTable",
    ["work.disassemble"] = "UI_PNC_Facility_RecyclingSpot",
    ["water.spigot"] = "UI_PNC_Facility_WaterSpigot",
    ["dining.table"] = "UI_PNC_Facility_DiningTable",
    ["health.bed"] = "UI_PNC_Facility_HospitalBed",
}
local ANCHOR_SELECT_TITLES = {
    ["sleep.bed"] = "UI_PNC_Facility_SelectBed",
    ["work.research"] = "UI_PNC_Facility_SelectResearchTable",
    ["work.blueprint"] = "UI_PNC_Facility_SelectResearchTable",
    ["work.reverse"] = "UI_PNC_Facility_SelectResearchTable",
    ["work.craft"] = "UI_PNC_Facility_SelectCraftStation",
    ["work.disassemble"] = "UI_PNC_Facility_SelectDisassemblyStation",
    ["water.spigot"] = "UI_PNC_Facility_SelectWaterSpigot",
    ["dining.table"] = "UI_PNC_Facility_SelectDiningTable",
    ["health.bed"] = "UI_PNC_Facility_SelectHospitalBed",
}
local ANCHOR_ASSIGN_TITLES = {
    ["sleep.bed"] = "UI_PNC_Facility_AssignBed",
    ["work.research"] = "UI_PNC_Facility_AssignResearchTable",
    ["work.blueprint"] = "UI_PNC_Facility_AssignResearchTable",
    ["work.reverse"] = "UI_PNC_Facility_AssignResearchTable",
    ["work.craft"] = "UI_PNC_Facility_AssignCraftStation",
    ["work.disassemble"] = "UI_PNC_Facility_AssignDisassemblyStation",
    ["water.spigot"] = "UI_PNC_Facility_AssignWaterSpigot",
    ["dining.table"] = "UI_PNC_Facility_AssignDiningTable",
    ["health.bed"] = "UI_PNC_Facility_AssignHospitalBed",
}

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
    local externalStockpile = facility
        and facility.definitionId == "stockpile"
        and role == "storage.stockpile"
    local boundary
    if role == "work.zone" then
        boundary = Support.WorkZoneRegion(facility)
    elseif externalStockpile then
        -- Stockpile storage is a mobile world region. It is still owned by
        -- this base, but its tiles are allowed to be outside the base zone.
        boundary = nil
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
            or externalStockpile
            and Support.Tr("UI_PNC_Facility_SelectStockpileAreaHelp",
                "Select a connected stockpile area; it may be outside the base territory.")
            or Support.Tr("UI_PNC_Facility_SelectAreaHelp",
                "Select one connected room inside the base territory."),
        initialRegion = existing and existing.region or Support.EmptyRegion(),
        guideRegion = boundary,
        guideLayers = Support.UsedGuideLayers(window, existing and existing.id),
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
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
        onConfirm = onConfirm,
    }
end

function Facility.BeginBuild(window, definitionId)
    local settlement = window.snapshot and window.snapshot.settlement
    if not settlement then return false end
    local definitions = PNC.FacilityDefinitions
    local definition = definitions and definitions.Get
        and definitions.Get(definitionId) or nil
    if definition and definition.directWorkstation == true then
        local objectInfoName = definition.buildRecipeObjectInfoName
            or definition.entityScript
        local catalog = PNC.BuildRecipeCatalog
        local descriptor = catalog and catalog.Get
            and catalog.Get(objectInfoName) or nil
        if not descriptor then return false, "BUILD_RECIPE_NOT_FOUND" end
        -- Direct workstations use the same native cursor/blueprint flow as
        -- the Building tab. The server binds the facility identity to this
        -- object-build order so no room/zone selector is involved.
        return Placement.Begin(window, {
            recipeKey = descriptor.recipeKey,
            objectInfoName = descriptor.objectInfoName,
            facilityDefinitionId = definitionId,
            facilityBaseId = settlement.id,
            facilityExpectedRevision = settlement.revision,
        })
    end
    local draft = { definitionId = definitionId, level = 1, components = {} }
    -- The selected build area is an abstract construction footprint, not a
    -- functional room. Native workstations bypass this selector entirely;
    -- legacy facilities still use the footprint only for placement.
    local role = definitionId == "farm" and "facility.footprint"
        or areaRole(draft) or "facility.footprint"
    Support.OpenSelector(window, areaOptions(window, draft, nil, function(region)
        PNC.Client.RequestCreateFacility({ baseId = settlement.id,
            expectedRevision = settlement.revision, definitionId = definitionId,
            component = { kind = "region", role = role, region = region } })
        Support.ApplyLocalResult(window)
    end))
    return true
end

function Facility.BeginArea(window, facility, requestedRole, componentId)
    local role = requestedRole or areaRole(facility)
    if not facility or not facility.id or not role then return false end
    local existing = componentId and Support.ComponentById(facility, componentId)
        or requestedRole == nil and Support.ComponentForRole(facility, role)
        or nil
    local options = areaOptions(window, facility, existing,
        function(region)
            PNC.Client.RequestSetFacilityComponent({ facilityId = facility.id,
                expectedRevision = facility.revision,
                component = { id = existing and existing.id or nil,
                    kind = "region", role = role, region = region,
                    desiredCrop = existing and existing.desiredCrop or nil,
                    policy = existing and existing.policy or nil } })
            Support.ApplyLocalResult(window)
        end, role)
    if not options then return false, "FACILITY_AREA_UNAVAILABLE" end
    local selector, reason = Support.OpenSelector(window, options)
    if not selector then return false, reason or "SELECTOR_UNAVAILABLE" end
    return true
end

function Facility.BeginCrop(window, facility, componentId)
    local plot = Support.ComponentById(facility, componentId)
    if not plot then return false end
    local PlantUI = require "PNC/UI/Communities/ColonyManagement/PNC_FarmingPlantModal"
    PlantUI.Open(window.snapshot and window.snapshot.storage, plot,
        function(cropID)
            PNC.Client.RequestSetFarmPlotCrop({
                facilityId = facility.id, plotId = plot.id,
                expectedRevision = facility.revision, desiredCrop = cropID,
            })
            Support.ApplyLocalResult(window)
        end,
        function(debugAction)
            PNC.Client.RequestFarmPlotDebug({
                facilityId = facility.id, plotId = plot.id,
                expectedRevision = facility.revision,
                debugAction = debugAction,
            })
            Support.ApplyLocalResult(window)
        end,
        function()
            local current = PNC.Farming.NormalizePolicy(plot.policy)
            local enabled = not (current.autoPlant and current.autoWater
                and current.autoHarvest and current.autoReplant)
            PNC.Client.RequestSetFarmPlotPolicy({
                facilityId = facility.id, plotId = plot.id,
                expectedRevision = facility.revision,
                policy = { autoPlant = enabled, autoWater = enabled,
                    autoHarvest = enabled, autoReplant = enabled },
            })
            Support.ApplyLocalResult(window)
        end,
        function()
            Facility.BeginArea(window, facility, "growing.plot", plot.id)
        end)
    return true
end

function Facility.NextAnchorRole(facility)
    local level = facility and PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level) or nil
    local limits = level and level.componentLimits or {}
    local roles = {}
    for role, limit in pairs(limits) do
        if limit.kind == "anchor" then roles[#roles + 1] = role end
    end
    table.sort(roles)
    for _, role in ipairs(roles) do
        if not Support.ComponentForRole(facility, role) then return role end
    end
    return roles[1]
end

function Facility.AnchorLabel(role)
    local key = ANCHOR_LABELS[role]
    return key and getText(key)
        or string.upper(string.gsub(role or "", "[%.]", " "))
end

function Facility.AnchorAssignLabel(role)
    local key = ANCHOR_ASSIGN_TITLES[role]
    return key and getText(key) or Facility.AnchorLabel(role)
end

function Facility.BeginPoint(window, _, facility, requestedRole, componentId)
    local role = requestedRole
        or Facility.NextAnchorRole(facility)
    local existing = componentId
        and Support.ComponentById(facility, componentId)
        or requestedRole == nil
            and Support.ComponentForRole(facility, role) or nil
    local selectTitleKey = ANCHOR_SELECT_TITLES[role]
    local boundary = Support.FacilityRegion(facility)
    Support.OpenSelector(window, {
        title = selectTitleKey and getText(selectTitleKey)
            or Support.Tr("UI_PNC_Facility_SelectStation",
                "SELECT FACILITY COMPONENT"),
        instruction = role == "sleep.bed" and Support.Tr("UI_PNC_Facility_SelectBedHelp",
            "Choose a sleeping spot. A bed is used automatically when present; otherwise the colonist sleeps on the floor.")
            or getText("UI_PNC_Facility_SelectStationHelp"),
        selectionKind = "point",
        guideRegion = boundary,
        guideLayers = Support.UsedGuideLayers(window,
            existing and existing.id),
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
        validate = function(region)
            local bounds = GridRegion.bounds(region)
            if not bounds or not GridRegion.containsPoint(boundary,
                bounds.minX, bounds.minY, bounds.minZ)
            then return false, Shared.SettlementReason(
                "OUTSIDE_FACILITY") end
            return true
        end,
        onConfirm = function(region)
            local bounds = GridRegion.bounds(region)
            PNC.Client.RequestSetFacilityComponent({ facilityId = facility.id,
                expectedRevision = facility.revision,
                component = { id = existing and existing.id or nil,
                    kind = "anchor", role = role,
                    x = bounds.minX, y = bounds.minY, z = bounds.minZ,
                    targetResolver = role == "sleep.bed" and "sleepSpot" or nil } })
            Support.ApplyLocalResult(window)
        end,
    })
end

return Facility
