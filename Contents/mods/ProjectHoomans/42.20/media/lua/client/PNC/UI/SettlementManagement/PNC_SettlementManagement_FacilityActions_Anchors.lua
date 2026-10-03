local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Support = require "PNC/UI/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
local Facility = PNC.SettlementManagementFacilityActions
local Internal = Facility.Internal
local ANCHOR_LABELS = Internal.AnchorLabels
local ANCHOR_SELECT_TITLES = Internal.AnchorSelectTitles
local ANCHOR_ASSIGN_TITLES = Internal.AnchorAssignTitles

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
    return key and PNC.Translation.GetKey(key)
        or string.upper(string.gsub(role or "", "[%.]", " "))
end

function Facility.AnchorAssignLabel(role)
    local key = ANCHOR_ASSIGN_TITLES[role]
    return key and PNC.Translation.GetKey(key) or Facility.AnchorLabel(role)
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
        title = selectTitleKey and PNC.Translation.GetKey(selectTitleKey)
            or Support.Tr("UI_PNC_Facility_SelectStation",
                "SELECT FACILITY COMPONENT"),
        instruction = role == "sleep.bed" and Support.Tr("UI_PNC_Facility_SelectBedHelp",
            "Choose a sleeping spot. A bed is used automatically when present; otherwise the colonist sleeps on the floor.")
            or PNC.Translation.GetKey("UI_PNC_Facility_SelectStationHelp"),
        selectionKind = "point",
        guideRegion = boundary,
        guideLayers = Support.UsedGuideLayers(window,
            existing and existing.id),
        guideRenderZ = nil,
        debugLabel = tostring(facility.definitionId or "facility")
            .. ":" .. tostring(role),
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
