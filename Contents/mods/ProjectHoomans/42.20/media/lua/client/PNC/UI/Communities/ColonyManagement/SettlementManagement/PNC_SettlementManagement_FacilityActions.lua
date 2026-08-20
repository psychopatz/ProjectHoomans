local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Support = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"

local Facility = {}

local ANCHOR_LABELS = {
    ["sleep.bed"] = "UI_PNC_Facility_SleepSpot",
    ["work.research"] = "UI_PNC_Facility_ResearchStation",
    ["work.blueprint"] = "UI_PNC_Facility_ArchitectBench",
    ["work.reverse"] = "UI_PNC_Facility_Lab",
    ["work.craft"] = "UI_PNC_Facility_CraftingTable",
    ["work.disassemble"] = "UI_PNC_Facility_RecyclingSpot",
    ["water.spigot"] = "UI_PNC_Facility_WaterSpigot",
}
local ANCHOR_SELECT_TITLES = {
    ["sleep.bed"] = "UI_PNC_Facility_SelectBed",
    ["work.research"] = "UI_PNC_Facility_SelectResearchStation",
    ["work.blueprint"] = "UI_PNC_Facility_SelectArchitectBench",
    ["work.reverse"] = "UI_PNC_Facility_SelectLab",
    ["work.craft"] = "UI_PNC_Facility_SelectCraftStation",
    ["work.disassemble"] = "UI_PNC_Facility_SelectDisassemblyStation",
    ["water.spigot"] = "UI_PNC_Facility_SelectWaterSpigot",
}
local ANCHOR_ASSIGN_TITLES = {
    ["sleep.bed"] = "UI_PNC_Facility_AssignBed",
    ["work.research"] = "UI_PNC_Facility_AssignResearchStation",
    ["work.blueprint"] = "UI_PNC_Facility_AssignArchitectBench",
    ["work.reverse"] = "UI_PNC_Facility_AssignLab",
    ["work.craft"] = "UI_PNC_Facility_AssignCraftStation",
    ["work.disassemble"] = "UI_PNC_Facility_AssignDisassemblyStation",
    ["water.spigot"] = "UI_PNC_Facility_AssignWaterSpigot",
}

local function areaRole(facility)
    local level = facility and PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level or 1) or nil
    local roles = {}
    for role, limit in pairs(level and level.componentLimits or {}) do
        if limit.kind == "region" then roles[#roles + 1] = role end
    end
    table.sort(roles)
    return roles[1]
end

Facility.AreaRole = areaRole

local function areaOptions(window, facility, existing, onConfirm)
    local isDraft = not facility or facility.id == nil
    local role = areaRole(facility)
    -- Construction always selects an abstract footprint. Anchor-only
    -- facilities (research, utilities, and future workstation buildings) do
    -- not declare a functional region role, so their draft still needs this
    -- selector role.
    if not role and isDraft then role = "facility.footprint" end
    if not role then return nil end
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level or 1)
    local limit = level and level.componentLimits[role] or {}
    local boundary = isDraft and Support.BaseRegion(window)
        or Support.FacilityRegion(facility)
    return {
        title = Support.Tr("UI_PNC_Facility_SelectArea", "SELECT FACILITY AREA"),
        instruction = role == "facility.footprint"
            and Support.Tr("UI_PNC_Facility_SelectFootprintHelp",
                "Select the building footprint inside the base territory.")
            or role == "farm.field"
            and Support.Tr("UI_PNC_Facility_SelectFarmlandHelp",
                "Select connected cultivated farmland inside the base.")
            or Support.Tr("UI_PNC_Facility_SelectAreaHelp",
                "Select one connected room inside the base territory."),
        initialRegion = existing and existing.region or Support.EmptyRegion(),
        guideRegion = boundary,
        guideLayers = Support.UsedGuideLayers(window, existing and existing.id),
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
        maxTiles = limit.maxTotalTiles,
        requiredSquareRule = limit.worldRule,
        validate = function(region, stats)
            local ok, reason = Support.ValidateConnected(region)
            if ok and not GridRegion.containsRegion(boundary, region) then
                ok, reason = false, isDraft and "OUTSIDE_BASE"
                    or "OUTSIDE_FACILITY"
            end
            if ok and limit.maxTotalTiles and stats.tileCount > limit.maxTotalTiles then
                ok, reason = false, "FACILITY_AREA_TOO_LARGE"
            end
            return ok, ok and nil or Shared.SettlementReason(reason)
        end,
        onConfirm = onConfirm,
    }
end

function Facility.BeginBuild(window, definitionId)
    local settlement = window.snapshot and window.snapshot.settlement
    if not settlement then return false end
    local draft = { definitionId = definitionId, level = 1, components = {} }
    -- The selected build area is an abstract construction footprint, not a
    -- functional room. Facilities such as Research therefore do not need a
    -- fake region component just to be placeable.
    local role = areaRole(draft) or "facility.footprint"
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
    if not role then return false end
    local existing = componentId and Support.ComponentById(facility, componentId)
        or requestedRole == nil and Support.ComponentForRole(facility, role)
        or nil
    Support.OpenSelector(window, areaOptions(window, facility, existing,
        function(region)
            PNC.Client.RequestSetFacilityComponent({ facilityId = facility.id,
                expectedRevision = facility.revision,
                component = { id = existing and existing.id or nil,
                    kind = "region", role = role, region = region } })
            Support.ApplyLocalResult(window)
        end))
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

function Facility.BeginPoint(window, kind, facility, requestedRole, componentId)
    local role = requestedRole
        or kind == "facility_anchor" and Facility.NextAnchorRole(facility)
        or kind == "bed" and "sleep.bed" or nil
    local anchor = role ~= nil
    local existing = anchor and componentId
        and Support.ComponentById(facility, componentId)
        or anchor and requestedRole == nil
            and Support.ComponentForRole(facility, role) or nil
    local selectTitleKey = anchor and ANCHOR_SELECT_TITLES[role] or nil
    local boundary = anchor and Support.FacilityRegion(facility)
        or Support.BaseRegion(window)
    Support.OpenSelector(window, {
        title = selectTitleKey and getText(selectTitleKey)
            or anchor and Support.Tr("UI_PNC_Facility_SelectStation",
                "SELECT FACILITY COMPONENT")
            or Support.Tr("UI_PNC_Stockpile_SelectNode", "SELECT STOCKPILE ACCESS TILE"),
        instruction = role == "sleep.bed" and Support.Tr("UI_PNC_Facility_SelectBedHelp",
            "Choose a sleeping spot. A bed is used automatically when present; otherwise the colonist sleeps on the floor.")
            or anchor and getText("UI_PNC_Facility_SelectStationHelp")
            or Support.Tr("UI_PNC_Point_SelectHelp", "Click one tile, then confirm."),
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
                anchor and "OUTSIDE_FACILITY" or "OUTSIDE_BASE") end
            return true
        end,
        onConfirm = function(region)
            local bounds = GridRegion.bounds(region)
            if anchor then
                PNC.Client.RequestSetFacilityComponent({ facilityId = facility.id,
                    expectedRevision = facility.revision,
                    component = { id = existing and existing.id or nil,
                        kind = "anchor", role = role,
                        x = bounds.minX, y = bounds.minY, z = bounds.minZ,
                        targetResolver = role == "sleep.bed" and "sleepSpot" or nil } })
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
