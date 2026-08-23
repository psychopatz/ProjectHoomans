local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup.lua"
)
local providers = {
    "PNC_BodyLifecycle_Startup_Identity",
    "PNC_BodyLifecycle_Startup_Removal",
    "PNC_BodyLifecycle_Startup_RecordCleanup",
    "PNC_BodyLifecycle_Startup_Sweep",
    "PNC_BodyLifecycle_Startup_Coordinator",
}
local publicFunctions = {
    "CleanupRecordShells",
    "SweepPersistedLiveShells",
    "InterceptLoadedShell",
    "BeginStartupBodyCleanup",
    "RunStartupBodyCleanupNow",
    "PumpStartupBodyCleanup",
    "IsStartupBodyCleanupComplete",
    "OnEarlyZombieUpdate",
    "OnEarlyLivingCharacter",
    "OnEarlyWorldReady",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Presence/PNC_BodyLifecycle/'
            .. "PNC_BodyLifecycle_Startup/" .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    BodyLifecycle = { Internal = {} },
    Core = {},
    Const = {},
}
Events = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.BodyLifecycle[functionName]),
        "function",
        "entry point should preserve BodyLifecycle." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[
        "PNC/Core/Presence/PNC_BodyLifecycle/"
            .. "PNC_BodyLifecycle_Startup/" .. providers[i]
    ] = nil
end

T.finish("pnc_body_lifecycle_startup_presence_boundary_smoke")
