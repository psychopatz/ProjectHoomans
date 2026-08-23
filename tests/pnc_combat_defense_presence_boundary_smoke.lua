local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/PNC_Combat_Defense.lua"
)
local providers = {
    "PNC_Combat_Defense_State",
    "PNC_Combat_Defense_DamageChance",
    "PNC_Combat_Defense_NearMiss",
    "PNC_Combat_Defense_DamageModel",
    "PNC_Combat_Defense_Legacy",
    "PNC_Combat_Defense_Resolve",
}
local publicFunctions = {
    "CountNearbyZombies",
    "Refresh",
    "CalculateDamageChance",
    "CalculateAvoidChance",
    "ResolveZombieAttack",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Combat/PNC_Combat_Defense/'
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
    "PNC/Core/Combat/PNC_Combat_Defense.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.CombatDefense[functionName]),
        "function",
        "entry point should preserve CombatDefense." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[
        "PNC/Core/Combat/PNC_Combat_Defense/" .. providers[i]
    ] = nil
end

T.finish("pnc_combat_defense_presence_boundary_smoke")
