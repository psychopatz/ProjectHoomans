package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/?.lua",
    package.path,
}, ";")

getSpecificPlayer = function()
    return { getZ = function() return 0 end }
end

package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
] = function()
    return { SettlementReason = function(reason) return reason end }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return { containsRegion = function() return true end }
end

local openedOptions
local request
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
] = function()
    return {
        Tr = function(_, fallback) return fallback end,
        EmptyRegion = function() return { levels = {} } end,
        BaseRegion = function() return { levels = {} } end,
        FacilityRegion = function() return { levels = {} } end,
        UsedGuideLayers = function() return {} end,
        ValidateConnected = function() return true end,
        OpenSelector = function(_, options)
            assert(type(options) == "table",
                "anchor-only facility passed nil selector options")
            openedOptions = options
            return true
        end,
        ApplyLocalResult = function() end,
    }
end

PNC = {
    FacilityDefinitions = {
        GetLevel = function(definitionId)
            assert(definitionId == "research_facility",
                "unexpected facility definition")
            return { componentLimits = {
                ["work.research"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
            } }
        end,
    },
    Client = {
        RequestCreateFacility = function(payload) request = payload end,
    },
}

local Facility = require(
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/"
    .. "PNC_SettlementManagement_FacilityActions")
local window = { snapshot = { settlement = { id = "base:1", revision = 4 } } }

assert(Facility.BeginBuild(window, "research_facility") == true,
    "research facility build did not open")
assert(openedOptions ~= nil, "research facility selector was not opened")
assert(string.find(openedOptions.instruction, "building footprint", 1, true),
    "anchor-only facility did not use footprint instructions")

local region = { levels = { [0] = { rows = {} } } }
openedOptions.onConfirm(region)
assert(request and request.component,
    "confirmed footprint did not submit facility creation")
assert(request.component.role == "facility.footprint",
    "confirmed footprint used the wrong construction role")
assert(request.component.region == region,
    "confirmed footprint did not preserve the selected region")

print("pnc_anchor_only_facility_build_selector_smoke: ok")
