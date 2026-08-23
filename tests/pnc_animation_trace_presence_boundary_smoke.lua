local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Visuals/PNC_AnimationTrace.lua"
)
local prefix = "PNC/Core/Visuals/PNC_AnimationTrace/"
local providers = {
    "PNC_AnimationTrace_Core",
    "PNC_AnimationTrace_Capture",
    "PNC_AnimationTrace_Diagnostics",
    "PNC_AnimationTrace_Lifecycle",
    "PNC_AnimationTrace_Queries",
}
local publicFunctions = {
    "Begin", "Ensure", "Sample", "MarkFinishing", "End", "Get",
    "GetOverlayLine", "DumpBody", "DumpNPC", "DumpAll", "Reset",
    "SetEnabled",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = { Core = { Now = function() return 0 end } }
T.load("ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_AnimationTrace.lua")
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(type(PNC.AnimationTrace[functionName]), "function",
        "entry point should preserve AnimationTrace." .. functionName)
end
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_animation_trace_presence_boundary_smoke")
