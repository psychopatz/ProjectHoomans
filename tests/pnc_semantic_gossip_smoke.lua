local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}
PNC.Identity = {
    HashText = function(value, seed)
        local hash = tonumber(seed) or 5381
        local index
        for index = 1, #tostring(value or "") do
            hash = (hash * 33 + string.byte(value, index)) % 2147483646
        end
        return math.max(1, hash)
    end,
    MixSeed = function(seed)
        return tonumber(seed)
    end,
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Relationships/PNC_EntityRef.lua"
)
local memory = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Conversation/Memory/PNC_ConversationMemory.lua"
)
T.load(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/Memory/EventTypes/00_PNC_ConversationMemoryEventTypes.lua"
)
T.load(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/Memory/GossipTemplates/00_PNC_ConversationGossipTemplates.lua"
)

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Topics = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTopicCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local EntityResolver = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticEntityResolver.lua"
)
local ReferenceResolver = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueReferenceResolver.lua"
)

local text = "Did you hear that Sarah got bitten?"
local parsed = Semantic.Parser.Parse(text)
T.equal(parsed.intent, "GOSSIP", "gossip is a first-class speech act")
T.equal(parsed.speechAct, "GOSSIP", "gossip keeps its speech-act identity")
T.equal(parsed.target.unresolved, true,
    "gossip names remain unresolved until the entity gateway authorizes them")
T.equal(parsed.slots.information.event, "BITTEN",
    "gossip preserves the compositional event payload")
Topics.Annotate(parsed, text)
T.equal(parsed.extensions.topic.id, "gossip",
    "gossip receives its own current-topic classification")

local entityIndex = EntityResolver.BuildIndex({
    { id = "sarah", entityType = "npc", name = "Sarah" },
})
local router = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    contextResolver = function(ir, state, context, options)
        local output = ReferenceResolver.Resolve(ir, state, context, options)
        Topics.Annotate(output, text)
        return output
    end,
    policy = Policy,
    context = {
        llmEnabled = false,
        semanticEntityIndex = entityIndex,
    },
})

local preview = router:Preview(text)
T.equal(preview.ir.target.id, "sarah",
    "known gossip subjects resolve through the shared entity resolver")
T.equal(preview.ir.diagnostics.unresolvedEntity, false,
    "resolved gossip is safe for deterministic handling")
T.equal(preview.decision.route, "deterministic",
    "known gossip does not require the LLM")
T.equal(preview.decision.branch, "GOSSIP_RECEIVED",
    "gossip selects a semantic response branch")
T.equal(preview.decision.response.fallback,
    "I haven't heard anything about Sarah yet.",
    "local gossip response remains honest when private knowledge is absent")

local remembered = router:Preview("what's the gossip?", {
    llmEnabled = false,
    semanticEntityIndex = entityIndex,
    npcGossip = {
        statements = {
            "I got away when a whole horde came after me.",
            "Sarah stood up for someone during an attack.",
        },
    },
})
T.equal(remembered.decision.response.fallback,
    "I got away when a whole horde came after me. Sarah stood up for someone during an attack.",
    "gossip response uses the server-provided shareable memories")

local indexedRecords = {}
PNC.Registry = {
    Get = function(id) return indexedRecords[tostring(id)] end,
}
local function candidate(eventCode, targetID, expectedCode)
    local targetRecord = {
        id = targetID,
        name = targetID,
        identitySeed = 37,
    }
    local targetKey = PNC.EntityRef.ForNPC(targetID)
    indexedRecords[targetID] = targetRecord
    local target = memory.Events.ResolveTarget(targetKey)
    local speaker = eventCode == 1104 and targetRecord or {
        id = "speaker_" .. targetID,
        identitySeed = 91,
    }
    speaker.memory = {
        v = memory.Events.VERSION,
        d = 1,
        l = {
            eventCode,
            target.seed,
            1,
            memory.Events.FLAG_SHAREABLE + memory.Events.FLAG_DURABLE,
        },
    }
    local codes = memory.Events.BuildGossipCodes(
        speaker,
        targetKey,
        targetRecord.name,
        "colonist",
        memory.Events.MAX_GOSSIP
    )
    T.equal(codes[1], expectedCode,
        "shareable event memory becomes a registered gossip candidate")
    return memory.GetGossipTemplateByCode(codes[1])
end

local abandonment = candidate(1102, "abandoned_subject", 2003)
T.equal(abandonment.textKey, "negative.warning.abandoned",
    "abandonment maps to the localized warning candidate")
local protection = candidate(1103, "protected_subject", 1003)
T.equal(protection.textKey, "positive.protection",
    "protection maps to the localized praise candidate")
local hordeSurvival = candidate(1104, "horde_survivor", 4002)
T.equal(hordeSurvival.textKey, "neutral.horde_survival",
    "horde survival maps to the localized self-story candidate")
local rescue = candidate(1101, "rescued_subject", 1002)
T.equal(rescue.textKey, "positive.rescue.return",
    "rescue remains an active registered gossip candidate")

T.finish("pnc_semantic_gossip_smoke")
