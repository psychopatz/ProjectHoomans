local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_Presence.lua"
)
local providers = {
    "PNC_Presence_Budget",
    "PNC_Presence_Position",
    "PNC_Presence_Decisions",
    "PNC_Presence_Materialize",
    "PNC_Presence_Abstract",
    "PNC_Presence_Reconcile",
}
local publicFunctions = {
    "BeginServerTick",
    "ShouldMaterialize",
    "ShouldAbstract",
    "Materialize",
    "Abstract",
    "Reconcile",
    "RefreshMaterializationCandidates",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Presence/PNC_Presence/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    Core = {},
    Const = {},
    Registry = {},
    Health = {},
    Animation = {},
    Visuals = {},
    Equipment = {},
    PathService = {},
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_Presence.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.Presence[functionName]),
        "function",
        "entry point should preserve Presence." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[
        "PNC/Core/Presence/PNC_Presence/" .. providers[i]
    ] = nil
end

T.finish("pnc_presence_presence_boundary_smoke")
