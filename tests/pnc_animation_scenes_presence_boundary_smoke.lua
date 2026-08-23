local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Visuals/PNC_AnimationScenes.lua"
)
local providers = {
    "PNC_AnimationScenes_Normalization",
    "PNC_AnimationScenes_Registry",
    "PNC_AnimationScenes_Playback",
    "PNC_AnimationScenes_Lifecycle",
    "PNC_AnimationScenes_Safety",
    "PNC_AnimationScenes_Idle",
    "PNC_AnimationScenes_Tick",
}
local publicFunctions = {
    "Register",
    "Unregister",
    "Get",
    "List",
    "ListPools",
    "ChoosePoolScene",
    "Request",
    "Stop",
    "RequestFromPool",
    "Interrupt",
    "InterruptForSafety",
    "OnExternalBump",
    "TryIdle",
    "Tick",
    "StartSurrender",
    "StopSurrender",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Visuals/PNC_AnimationScenes/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    Core = {},
    Const = {},
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Visuals/PNC_AnimationScenes.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.AnimationScenes[functionName]),
        "function",
        "entry point should preserve AnimationScenes." .. functionName
    )
end

T.finish("pnc_animation_scenes_presence_boundary_smoke")
