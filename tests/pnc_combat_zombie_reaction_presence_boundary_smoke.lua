local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/PNC_Combat_ZombieReaction.lua"
)
local prefix = "PNC/Core/Combat/PNC_Combat_ZombieReaction/"
local providers = {
    "PNC_Combat_ZombieReaction_Core",
    "PNC_Combat_ZombieReaction_Shove",
    "PNC_Combat_ZombieReaction_Hits",
    "PNC_Combat_ZombieReaction_Runtime",
}
local publicFunctions = {
    "Start",
    "ApplyWeaponHit",
    "ApplyReplicatedHit",
    "IsEngineHitSettling",
    "Clear",
    "Pump",
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
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/PNC_Combat_ZombieReaction.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.CombatZombieReaction[functionName]),
        "function",
        "entry point should preserve CombatZombieReaction." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_combat_zombie_reaction_presence_boundary_smoke")
