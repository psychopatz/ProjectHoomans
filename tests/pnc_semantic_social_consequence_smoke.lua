local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local emitted = {}
PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}
PNC = {
    Semantics = {},
    EntityRef = {
        ForNPC = function(id)
            return "npc:" .. tostring(id)
        end,
    },
    SocialEvents = {
        Emit = function(event)
            emitted[#emitted + 1] = event
            return {
                ok = true,
                eventID = event.id,
                eventType = event.type,
                relationshipsChanged = 1,
            }
        end,
    },
}

local Consequences = T.load(
    "ProjectHoomans", "server",
    "PNC/Semantics/PNC_SemanticSocialConsequenceService.lua"
)

T.equal(
    Consequences.EventTypeFor("INSULT"),
    "npc_dialogue_insult",
    "NPC insult has its own SocialEvent type"
)
T.equal(
    Consequences.EventTypeFor("HOSTILE_REMARK"),
    "npc_dialogue_hostile_remark",
    "NPC hostile remark has its own SocialEvent type"
)
T.equal(
    Consequences.EventTypeFor("THREATEN"),
    "npc_dialogue_threat",
    "NPC threat has its own SocialEvent type"
)
T.equal(
    Consequences.EventTypeFor("ACKNOWLEDGE"),
    nil,
    "ordinary acknowledgement has no forced relationship mutation"
)

local applied = Consequences.Apply({
    sceneID = "scene:social:hostile",
    sequence = 3,
    request = {
        sourceID = "npc-raider-a",
        responderID = "npc-raider-b",
        intent = "HOSTILE_REMARK",
        speechAct = "HOSTILE_REMARK",
    },
    strategy = "DOUBLE_DOWN",
    motive = "DISPUTE",
    occurredAt = 123.5,
})
T.truthy(applied.accepted, "hostile NPC act is handed to SocialEvent authority")
T.truthy(applied.applied, "SocialEvent acceptance is reported as applied")
T.equal(#emitted, 1, "one autonomous semantic act emits one social event")
T.equal(emitted[1].type, "npc_dialogue_hostile_remark",
    "event type is NPC-specific")
T.equal(emitted[1].sourceSystem, "semantic_scene",
    "existing SocialEvent authority receives explicit Scene source")
T.equal(emitted[1].actorKey, "npc:npc-raider-a",
    "semantic speaker becomes social-event actor")
T.equal(emitted[1].targetKey, "npc:npc-raider-b",
    "semantic recipient becomes social-event target")
T.equal(emitted[1].occurredAt, 123.5,
    "authoritative timestamp is preserved")
T.equal(emitted[1].context.semanticStrategy, "DOUBLE_DOWN",
    "social event keeps semantic strategy provenance")
T.equal(emitted[1].context.socialMotive, "DISPUTE",
    "social event keeps social motive provenance")
T.truthy(string.find(
    emitted[1].id,
    "social:semantic_scene:scene:social:hostile:3:",
    1,
    true
), "event id is deterministic from Scene and semantic sequence")

local ordinary = Consequences.Apply({
    sceneID = "scene:social:ordinary",
    sequence = 4,
    request = {
        sourceID = "npc-a",
        responderID = "npc-b",
        intent = "ACKNOWLEDGE",
        speechAct = "ACKNOWLEDGE",
    },
})
T.falsy(ordinary.applied,
    "non-consequential semantic acts do not mutate relationship authority")
T.equal(ordinary.reason, "social_consequence_not_applicable",
    "ordinary no-op consequence is explicit")
T.equal(#emitted, 1,
    "non-consequential semantic acts emit no SocialEvent")

local Definitions = T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialEventDefinitions.lua"
)
for _, eventType in ipairs({
    "npc_dialogue_hostile_remark",
    "npc_dialogue_insult",
    "npc_dialogue_threat",
}) do
    local definition = Definitions[eventType]
    T.truthy(definition, eventType .. " relationship definition exists")
    T.truthy(definition.allowedSourceSystems.semantic_scene,
        eventType .. " only accepts the semantic Scene authority")
    T.truthy(definition.targetMemory
        and string.find(definition.targetMemory.type, "npc_", 1, true) == 1,
        eventType .. " does not masquerade as a player memory")
end

local Conduct = T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Conduct/PNC_ConductDefinitions.lua"
)
for _, eventType in ipairs({
    "npc_dialogue_hostile_remark",
    "npc_dialogue_insult",
    "npc_dialogue_threat",
}) do
    T.truthy(Conduct[eventType],
        eventType .. " has existing Conduct-service evidence policy")
end

T.finish("pnc_semantic_social_consequence_smoke")
