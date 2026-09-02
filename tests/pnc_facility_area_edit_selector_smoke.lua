local T = require "tests/support/test"

T.addPackagePaths()

getSpecificPlayer = function()
    return { getZ = function() return 0 end }
end

package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
] = function()
    return { SettlementReason = function(reason) return reason end }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsRegion = function() return true end,
    }
end

local opened
local request
local baseRegion = { levels = { [0] = { rows = { [10] = { 10, 12 } } } } }
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
] = function()
    return {
        Tr = function(_, fallback) return fallback end,
        EmptyRegion = function() return { levels = {} } end,
        BaseRegion = function() return baseRegion end,
        FacilityRegion = function(facility) return facility.constructionRegion end,
        WorkZoneRegion = function() return { levels = {} } end,
        ComponentById = function(facility, id)
            for _, component in ipairs(facility.components or {}) do
                if component.id == id then return component end
            end
        end,
        ComponentForRole = function() return nil end,
        UsedGuideLayers = function() return {} end,
        ValidateConnected = function() return true end,
        OpenSelector = function(_, options)
            opened = options
            return options
        end,
        ApplyLocalResult = function() end,
    }
end
package.preload["PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacement"] =
    function() return {} end

PNC = {
    Farming = {},
    FacilityDefinitions = {
        GetLevel = function(definitionId)
            if definitionId == "stockpile" then
                return { componentLimits = {
                    ["storage.stockpile"] = { kind = "region",
                        minCount = 1, maxCount = 1,
                        minTotalTiles = 1, maxTotalTiles = 1000 },
                } }
            end
            return { componentLimits = {
                ["work.zone"] = { kind = "region", minCount = 1,
                    maxCount = 1, minTotalTiles = 1, maxTotalTiles = 1 },
            } }
        end,
    },
    Client = {
        RequestSetFacilityComponent = function(payload) request = payload end,
    },
}

local Facility = require(
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/"
    .. "PNC_SettlementManagement_FacilityActions")
local region = { levels = { [0] = { rows = { [10] = { 10, 10 } } } } }
local window = { snapshot = { settlement = {
    id = "base:1", geometry = { region = baseRegion },
} } }
local facility = {
    id = "facility:1", definitionId = "forge", level = 1, revision = 7,
    constructionRegion = region,
    components = {{ id = "zone:1", kind = "region", role = "work.zone",
        region = region }},
}

T.truthy(Facility.BeginArea(window, facility, "work.zone", "zone:1"),
    "work-area edit did not open the selector")
T.equal(opened.selectionKind, "point",
    "work-area edit should use single-tile placement")
local replacement = { levels = { [0] = { rows = { [11] = { 10, 10 } } } } }
opened.onConfirm(replacement)
T.equal(request.facilityId, "facility:1",
    "work-area edit submitted the wrong facility")
T.equal(request.component.id, "zone:1",
    "work-area edit did not preserve the component identity")
T.equal(request.component.region, replacement,
    "work-area edit did not submit the placed tile")

opened = nil
T.truthy(Facility.BeginBuild(window, "stockpile"),
    "stockpile build did not open the area selector")
T.equal(opened.guideRegion, baseRegion,
    "draft stockpile did not receive the base guide region")
T.equal(opened.selectionKind, "region",
    "stockpile build should select a region")
T.truthy(opened.tileValidator,
    "base-constrained stockpile did not receive tile validation")
T.equal(opened.guideRenderZ, nil,
    "stockpile guide should render its stored region levels")
T.finish("pnc_facility_area_edit_selector_smoke")
