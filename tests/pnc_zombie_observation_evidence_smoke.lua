local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = {
    Semantics = {},
    Relationships = {},
    Conduct = {},
}
local Providers = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionProviders.lua"
)

local context = {
    npcID = "npc1",
    zombiePressure = "horde",
    zombieObservation = {
        nearbyCount = 10,
        hordeCount = 8,
        band = "horde",
        tacticalHorde = true,
    },
    semanticDialogueContext = {
        recentTurns = {},
    },
    worldContext = {
        worldAgeHours = 5,
    },
}
local projected = Providers.ProjectDialogue(context)
T.equal(projected.world.zombiePressure, "horde", "world pressure band")
T.equal(projected.world.nearbyZombieCount, 10, "world nearby count")
T.equal(projected.world.hordeZombieCount, 8, "world horde count")
T.truthy(projected.world.tacticalHorde, "world tactical horde")
T.truthy(projected.world.immediateDanger, "horde marks immediate danger")

local found
for _, row in ipairs(projected.evidence.rows or {}) do
    if row.providerID == "projecthoomans.zombie_observation" then
        found = row
        break
    end
end
T.truthy(found, "current zombie pressure is semantic evidence")
T.equal(found.sourceTier, "SESSION", "current pressure stays runtime/session")
T.equal(found.eventType, "zombie_pressure_current", "current event type")
T.equal(found.retentionSalience, 0, "current pressure is not retention weight")

T.finish("pnc_zombie_observation_evidence_smoke")
