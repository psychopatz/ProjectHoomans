local T = require "tests/support/test"

local MODEL = T.path("ProjectHoomans", "client", "")
    .. "PNC/UI/UniqueNPC/PNC_UniqueNPCDebugModel.lua"

PNC = {}
T.load(MODEL)

local snapshot = {
    entries = {
        {
            definitionId = "gorgon_ramsee",
            displayName = "Gorgon Ramsee",
            registered = true,
            status = "alive",
            spawned = true,
            isFemale = true,
            archetypeID = "chef",
            identitySeed = 42,
            runtime = {
                runtimeNpcId = "npcGorgonRamsee_ABC",
                name = "Gorgon Ramsee",
                presenceState = "live",
                tacticalClass = "neutral",
                x = 100,
                y = 200,
                z = 0,
                hpCurrent = 90,
                hpMax = 100,
                healthState = "healthy",
                affiliation = { id = "faction:chefs", name = "Chefs" },
                community = { id = "community:kitchen", name = "Kitchen" },
                skillLevels = { Cooking = 10 },
                skillBaseLevels = { Cooking = 10 },
            },
            authored = {
                skillLevels = { Cooking = 10 },
                startingItemCount = 1,
            },
        },
        {
            definitionId = "lost_unique",
            displayName = "Lost Unique",
            registered = true,
            status = "dead",
            spawned = false,
            deathReason = "test",
        },
        {
            definitionId = "broken_unique",
            displayName = "Broken Unique",
            registered = false,
            status = "unseen",
            registrationError = { reason = "invalid_definition" },
        },
    },
    registrationErrors = {
        { id = "not_loaded", displayName = "Not Loaded", reason = "bad" },
    },
}

local all = PNC.UniqueNPCDebugModel.BuildItems(snapshot, "All")
T.equal(#all, 4, "all unique NPCs and registration errors listed")
T.equal(all[1].label, "Gorgon Ramsee", "display name preserved")
T.truthy(all[1].locatable, "alive unique is locatable")

local alive = PNC.UniqueNPCDebugModel.BuildItems(snapshot, "Alive")
T.equal(#alive, 1, "alive filter")
local dead = PNC.UniqueNPCDebugModel.BuildItems(snapshot, "Dead")
T.equal(#dead, 1, "dead filter")
local problems = PNC.UniqueNPCDebugModel.BuildItems(snapshot, "Problems")
T.equal(#problems, 2, "problem filter")
local searched = PNC.UniqueNPCDebugModel.BuildItems(snapshot, "All", "gorgon")
T.equal(#searched, 1, "name search")

local rows = PNC.UniqueNPCDebugModel.BuildDetailRows(snapshot.entries[1])
local sawFaction = false
local sawSkills = false
for _, row in ipairs(rows) do
    if row.key == "faction" then
        sawFaction = true
        T.contains(row.value, "Chefs", "faction detail")
    end
    if row.key == "skills" then
        sawSkills = true
        T.contains(row.value, "Cooking=10", "skill detail")
    end
end
T.truthy(sawFaction, "faction detail row")
T.truthy(sawSkills, "skill detail row")
T.falsy(PNC.UniqueNPCDebugModel.IsLocatable(snapshot.entries[2]),
    "dead unique cannot be located")
T.finish("pnc_unique_npc_debug_model_smoke")
