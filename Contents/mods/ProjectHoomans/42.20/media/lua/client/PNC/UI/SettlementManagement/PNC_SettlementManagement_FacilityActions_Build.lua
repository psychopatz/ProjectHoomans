local Support = require "PNC/UI/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
local Placement = require "PNC/UI/Base/PNC_BaseBuildingPlacement"
local BuildAudit = require "PNC/Core/Diagnostics/PNC_BuildAudit"
local Facility = PNC.SettlementManagementFacilityActions
local areaRole = Facility.Internal.AreaRole
local areaOptions = Facility.Internal.AreaOptions

function Facility.BeginBuild(window, definitionId)
    local settlement = Support.Settlement and Support.Settlement(window)
        or window.snapshot and window.snapshot.settlement
    if not settlement then
        if BuildAudit.Enabled() then
            BuildAudit.Log("begin_rejected", {
                "definition=" .. tostring(definitionId),
                "reason=SETTLEMENT_UNAVAILABLE",
            })
        end
        return false, "SETTLEMENT_UNAVAILABLE"
    end
    local definitions = PNC.FacilityDefinitions
    local definition = definitions and definitions.Get
        and definitions.Get(definitionId) or nil
    if definition and definition.directWorkstation == true then
        local objectInfoName = definition.buildRecipeObjectInfoName
            or definition.entityScript
        local catalog = PNC.BuildRecipeCatalog
        local descriptor = catalog and catalog.Get
            and catalog.Get(objectInfoName) or nil
        if BuildAudit.Enabled() then
            BuildAudit.Log("begin_route", {
                "definition=" .. tostring(definitionId),
                "route=native_placement",
                "object=" .. tostring(objectInfoName),
                "descriptor=" .. tostring(descriptor ~= nil),
            })
        end
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
    if BuildAudit.Enabled() then
        BuildAudit.Log("begin_route", {
            "definition=" .. tostring(definitionId),
            "route=area_selector",
            "role=" .. tostring(role),
        })
    end
    -- The caller closes the build window when this returns true, so a selector
    -- that never opened has to report failure. Swallowing it left the player
    -- with no window, no selector and no explanation.
    local options = areaOptions(window, draft, nil, function(region)
        local requestId
        if BuildAudit.Enabled() then
            requestId = BuildAudit.TraceId()
            BuildAudit.Log("selector_confirmed", {
                BuildAudit.RequestField(requestId),
                "definition=" .. tostring(definitionId),
                "role=" .. tostring(role),
            })
        end
        PNC.Client.RequestCreateFacility({ baseId = settlement.id,
            expectedRevision = settlement.revision, definitionId = definitionId,
            requestId = requestId,
            component = { kind = "region", role = role, region = region } })
        Support.ApplyLocalResult(window)
    end)
    if not options then return false, "FACILITY_AREA_UNAVAILABLE" end
    -- Trace the selector's own lifecycle. Without this a selector that closes
    -- itself (or is closed by another request) looks identical to one that was
    -- never opened.
    options.onCancel = function()
        if BuildAudit.Enabled() then
            BuildAudit.Log("selector_cancelled", {
                "definition=" .. tostring(definitionId),
                "role=" .. tostring(role),
            })
        end
    end
    local selector, reason = Support.OpenSelector(window, options)
    if not selector then
        if BuildAudit.Enabled() then
            BuildAudit.Log("selector_failed", {
                "definition=" .. tostring(definitionId),
                "reason=" .. tostring(reason),
            })
        end
        return false, reason or "SELECTOR_UNAVAILABLE"
    end
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
            local PlantUI = require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FarmingPlantModal"
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
