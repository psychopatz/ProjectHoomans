local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_Health.lua"
)
local providers = {
    "PNC_Health_LiveState",
    "PNC_Health_Incapacitation",
    "PNC_Health_Death",
    "PNC_Health_Damage",
    "PNC_Health_Update",
}
local publicFunctions = {
    "Ensure",
    "MarkRecentDamage",
    "EnterIncapacitated",
    "ResumeFromIncapacitated",
    "Revive",
    "Recover",
    "CanRevive",
    "ApplyDamageToPlayer",
    "Kill",
    "ApplyDamage",
    "ApplyStrainDamage",
    "Update",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Health/PNC_Health/'
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
    "PNC/Core/Health/PNC_Health.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.Health[functionName]),
        "function",
        "entry point should preserve Health." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[
        "PNC/Core/Health/PNC_Health/" .. providers[i]
    ] = nil
end

T.finish("pnc_health_presence_boundary_smoke")
