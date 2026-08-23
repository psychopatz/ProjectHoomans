local T = require "tests/support/test"

local source = T.read("ProjectHoomans", "shared", "PNC/Core/API/PNC_API.lua")
local providers = {
    "Lifecycle", "HealthSnapshots", "MapPresentation", "DebugCommands",
    "Travel", "Conversations", "AnimationScenes", "MapCommands",
}
local publicFunctions = {
    "Spawn", "Despawn", "SetOrder", "SetHostility", "SetLoadout",
    "ApplyDamage", "ApplyDebugWound", "ApplyDebugInfection",
    "ClearKnoxInfection", "DebugBandageAlmostDirty", "GetSnapshot",
    "GetCharacterPayload", "DebugCommand",
}

local previous = 0
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "PNC/Core/API/PNC_API/' .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {}
T.load("ProjectHoomans", "shared", "PNC/Core/API/PNC_API.lua")
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(type(PNC.API[functionName]), "function",
        "entry point should preserve API." .. functionName)
end
for _, namespace in ipairs({
    "MapPresentation", "Travel", "Conversations", "AnimationScenes", "MapCommands",
}) do
    T.truthy(type(PNC.API[namespace]) == "table", namespace .. " namespace")
end
T.equal(type(PNC.API.Travel.Start), "function", "Travel.Start")
T.equal(type(PNC.API.Conversations.RegisterBlock), "function", "Conversations.RegisterBlock")
T.equal(type(PNC.API.AnimationScenes.Play), "function", "AnimationScenes.Play")
T.equal(type(PNC.API.MapCommands.RegisterHandler), "function", "MapCommands.RegisterHandler")
T.finish("pnc_api_presence_boundary_smoke")
