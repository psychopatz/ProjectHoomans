local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Visuals/PNC_Animation.lua"
)
local providers = {
    "PNC_Animation_BumpState",
    "PNC_Animation_LocomotionVariables",
    "PNC_Animation_NativeLocomotion",
    "PNC_Animation_LiveSetup",
    "PNC_Animation_Downed",
    "PNC_Animation_BumpPlayback",
    "PNC_Animation_BumpLifecycle",
    "PNC_Animation_LocomotionSync",
}

local previous = 0
for index = 1, #providers do
    local needle = "require \"PNC/Core/Visuals/PNC_Animation/"
        .. providers[index] .. "\""
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, providers[index] .. " load order")
    previous = position
end

T.finish("pnc_animation_presence_boundary_smoke")
