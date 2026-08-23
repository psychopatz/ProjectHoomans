local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Perception/PNC_Perception.lua"
)

local providers = {
    "ThreatHistory", "Visibility", "ActorSearch", "ZombieSearch",
    "ImmediateEnemy", "ImmediateThreat", "ZombieRanking", "OwnerDefense",
    "Resolvers",
}

local publicFunctions = {
    "RememberAttacker", "ResolveRecentAttacker", "IsTargetThreatening",
    "SelectPreferredTarget", "CanSeeWorldObject", "FindNearestEnemyPlayer",
    "FindNearestEnemyNPC", "FindNearestEnemyZombie",
    "FindImmediateEnemyZombie", "FindImmediateZombieThreat",
    "FindBestEnemyZombie", "CountEnemyZombies", "FindZombieByID",
    "FindOwnerThreateningZombie", "ResolveCompanionTarget",
    "ResolveCompanionProtectionTarget", "ResolveHostileTarget",
    "ResolveRoamingTarget",
}

for i = 1, #providers do
    local provider = providers[i]
    T.truthy(source:find(
        'require "PNC/Core/Perception/PNC_Perception/' .. provider .. '"',
        1,
        true
    ), "entry point should load " .. provider)
end

PNC = {
    Core = {}, Const = {}, SpatialIndex = {}, Registry = {},
    Relationships = {}, Stealth = {},
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Perception/PNC_Perception.lua"
)

for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(type(PNC.Perception[functionName]), "function",
        "entry point should preserve Perception." .. functionName)
end

T.truthy(type(PNC.Perception.Internal) == "table",
    "providers should share an internal contract")

T.finish("pnc_perception_presence_boundary_smoke")
