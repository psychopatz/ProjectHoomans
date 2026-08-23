local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Travel/PNC_Travel_Service.lua"
)
local providers = {
    "PNC_Travel_Service_Core",
    "PNC_Travel_Service_Control",
    "PNC_Travel_Service_Progression",
    "PNC_Travel_Service_Live",
    "PNC_Travel_Service_Projection",
}
local publicFunctions = {
    "WorldHour",
    "RegisterListener",
    "UnregisterListener",
    "Emit",
    "EnsureArrivalHandled",
    "Get",
    "Start",
    "SetState",
    "Pause",
    "Resume",
    "Cancel",
    "Retarget",
    "Advance",
    "SyncLivePosition",
    "ReachCurrentWaypoint",
    "TickLive",
    "GetCurrentTarget",
    "OnMaterialized",
    "OnAbstracted",
    "RefreshAbstractPositions",
    "GetProgress",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Travel/PNC_Travel_Service/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    Core = {},
    Const = {},
    Travel = {},
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Travel/PNC_Travel_Service.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.Travel.Service[functionName]),
        "function",
        "entry point should preserve Travel.Service." .. functionName
    )
end

T.finish("pnc_travel_service_presence_boundary_smoke")
