local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "UI/Relationships/PNC_RelationshipDebugModel.lua"

local function assertContains(rows, label, fragment)
    for _, row in ipairs(rows) do
        if row.label == label
            and string.find(row.value, fragment, 1, true)
        then
            return
        end
    end
    error("missing row " .. label .. " containing " .. fragment)
end

PNC = {}
dofile(FILE)

local targets = PNC.RelationshipDebugModel.BuildTargets({
    { id = "alice", name = "Alice", alive = true },
    { id = "bob", name = "Bob", alive = true },
    { id = "dead", name = "Dead", deathMarker = true },
}, "alice")
assert(#targets == 2, "current player plus one NPC target")
assert(targets[1].kind == "current_player",
    "current player target comes first")
assert(targets[2].id == "bob", "observer excluded from targets")

local rows = PNC.RelationshipDebugModel.BuildRows({
    observer = {
        label = "Alice",
        key = "npc:alice",
        morale = 3,
        moraleBaseline = 0,
        recordRevision = 8,
        presenceRevision = 2,
        socialRevision = 4,
        personality = {
            socialStyle = "outgoing",
            compassion = 0.7,
            sociability = 0.8,
            forgiveness = 0.6,
            bravery = 0.5,
            materialism = 0.4,
            aggression = 0.3,
            loyalty = 0.9,
        },
    },
    target = {
        label = "Bob",
        key = "npc:bob",
    },
    relationship = {
        exists = true,
        approval = 12,
        respect = 15,
        familiarity = 8,
        state = "neutral",
        previousState = "unknown",
        baselineApproval = 0,
        baselineRespect = 0,
        revision = 3,
        lastInteractionAt = 10,
        lastEvaluatedAt = 10,
    },
    reverse = {
        exists = true,
        approval = -5,
        respect = 2,
        familiarity = 4,
        state = "unknown",
        revision = 1,
    },
    cooldowns = { treated_wound = 20 },
    saturation = {
        treated_wound = { approval = 4, respect = 2 },
    },
    memories = {
        {
            id = "memory:1",
            type = "treated_wound",
            approvalEffect = 4,
            respectEffect = 2,
            moraleEffect = 2,
            currentStrength = 0.95,
            strength = 1,
            decayPerDay = 0.05,
            permanent = false,
            knowledgeSource = "experienced",
        },
    },
    actionResult = {
        ok = true,
        eventType = "treated_wound",
        eventID = "social:test",
        memoriesCreated = 1,
        relationshipsChanged = 1,
        details = {
            {
                baseEffects = {
                    approvalEffect = 4,
                    respectEffect = 2,
                    familiarityGain = 2,
                },
                modifiedEffects = {
                    approvalEffect = 5,
                    respectEffect = 3,
                    familiarityGain = 2.5,
                },
                modifierBreakdown = { compassion = 1.25 },
            },
        },
    },
}, true)

assertContains(rows, "Approval", "12.00")
assertContains(rows, "Revisions", "presence 2")
assertContains(rows, "Reverse direction", "stored")
assertContains(rows, "Saturation treated_wound", "approval=4")
assertContains(rows, "1. treated_wound", "memory:1")
assertContains(rows, "  strength", "0.9500 current")
assertContains(rows, "Last trigger", "treated_wound")
assertContains(rows, "  approval effect", "+4.00 -> +5.00")
assertContains(rows, "  modifier compassion", "1.25")

local unauthorized =
    PNC.RelationshipDebugModel.BuildRows(nil, false)
assertContains(unauthorized, "Access", "Admin/debug mode required")

print("pnc_relationship_debug_model_smoke: ok")
