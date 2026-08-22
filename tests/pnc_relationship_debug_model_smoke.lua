local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/")
    .. "UI/Relationships/PNC_RelationshipDebugModel.lua"

local function expectRowContaining(rows, label, fragment)
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
T.load(FILE)

local targets = PNC.RelationshipDebugModel.BuildTargets({
    { id = "alice", name = "Alice", alive = true },
    { id = "bob", name = "Bob", alive = true },
    { id = "dead", name = "Dead", deathMarker = true },
}, "alice")
T.truthy(#targets == 2, "current player plus one NPC target")
T.truthy(targets[1].kind == "current_player",
    "current player target comes first")
T.truthy(targets[2].id == "bob", "observer excluded from targets")

local rows = PNC.RelationshipDebugModel.BuildRows({
    observer = {
        label = "Alice",
        key = "npc:alice",
        morale = 3,
        moraleBaseline = 0,
        recordRevision = 8,
        presenceRevision = 2,
        socialRevision = 4,
        faction = {
            organizationalFaction = true,
            label = "Riverside Cooperative",
            factionID = "faction_riverside",
            archetypeID = "settler",
            membershipStatus = "member",
            role = "guard",
            rank = "officer",
            affiliationRevision = 2,
        },
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
        faction = {
            organizationalFaction = false,
            label = "No organizational faction",
        },
    },
    observerConduct = {
        entityKey = "npc:alice",
        revision = 2,
        scores = {
            reliability = 2, generosity = 0, compassion = 0,
            courage = 2, restraint = 0, honesty = 0,
            groupLoyalty = 1,
        },
        evidenceCount = 1,
        evidence = {},
    },
    targetConduct = {
        entityKey = "npc:bob",
        revision = 4,
        scores = {
            reliability = 3, generosity = 1, compassion = 8,
            courage = 5, restraint = 0, honesty = 0,
            groupLoyalty = 4,
        },
        evidenceCount = 1,
        evidence = {
            {
                id = "conduct:social:test:npc:bob:rescuer",
                eventID = "social:test",
                eventType = "saved_from_incapacitation",
                subjectKey = "npc:alice",
                createdAt = 5,
                lastEvaluatedAt = 10,
                effects = { compassion = 8, courage = 5 },
                currentStrength = 0.99,
                decayPerDay = 0.0025,
                visibility = "direct",
                shareable = true,
                tags = { rescue = true },
            },
        },
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
}, true, nil, nil, {
    npcID = "npc:alice",
    source = "conversation",
    blockID = "projecthoomans:whats_up_local_activity_neutral",
    delta = { approval = 2, respect = -1, familiarity = 1 },
    effects = { { type = "pnc:relationship" } },
})

expectRowContaining(rows, "Approval", "12.00")
expectRowContaining(rows, "Revisions", "presence 2")
expectRowContaining(rows, "Observer faction", "Riverside Cooperative")
expectRowContaining(rows, "  faction ID", "faction_riverside")
expectRowContaining(rows, "  membership", "member")
expectRowContaining(rows, "Target faction", "No organizational faction")
expectRowContaining(rows, "Reverse direction", "stored")
expectRowContaining(rows, "Saturation treated_wound", "approval=4")
expectRowContaining(rows, "Observer conduct", "revision 2")
expectRowContaining(rows, "Target conduct", "revision 4")
expectRowContaining(rows, "  compassion", "8.00")
expectRowContaining(rows, "    visibility", "direct / shareable")
expectRowContaining(rows, "    event", "social:test")
expectRowContaining(rows, "1. treated_wound", "memory:1")
expectRowContaining(rows, "  strength", "0.9500 current")
expectRowContaining(rows, "Last trigger", "treated_wound")
expectRowContaining(rows, "  approval effect", "+4.00 -> +5.00")
expectRowContaining(rows, "  modifier compassion", "1.25")
expectRowContaining(rows, "  changed", "Approval +2.00")
expectRowContaining(rows, "Last conversation", "whats_up_local_activity")

local relationshipRows = PNC.RelationshipDebugModel.FilterRows(
    rows,
    "relationship"
)
expectRowContaining(relationshipRows, "Approval", "12.00")
expectRowContaining(relationshipRows, "Baseline approval", "0.00")

local personalityRows = PNC.RelationshipDebugModel.FilterRows(
    rows,
    "personality"
)
expectRowContaining(personalityRows, "Personality", "outgoing")
expectRowContaining(personalityRows, "  compassion", "0.70")

local memoryRows = PNC.RelationshipDebugModel.FilterRows(rows, "memories")
expectRowContaining(memoryRows, "Memories", "1")
expectRowContaining(memoryRows, "1. treated_wound", "memory:1")

local unauthorized =
    PNC.RelationshipDebugModel.BuildRows(nil, false)
expectRowContaining(unauthorized, "Access", "Admin/debug mode required")
T.finish("pnc_relationship_debug_model_smoke")

T.finish("pnc_relationship_debug_model_smoke")
