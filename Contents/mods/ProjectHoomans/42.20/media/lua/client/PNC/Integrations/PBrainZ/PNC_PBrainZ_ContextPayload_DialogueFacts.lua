-- Build request-local prompt facts; this module never persists NPC memory.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}

require "PNC/Conversation/Memory/PNC_ConversationMemory"
require "PNC/Conversation/Definitions/Memory/00_PNC_ConversationMemoryDefinitions"

local Memory = PNC.Conversation and PNC.Conversation.Memory or nil
local DialogueFacts = PNC.PBrainZ.ContextPayloadDialogueFacts or {}
PNC.PBrainZ.ContextPayloadDialogueFacts = DialogueFacts

local MAX_FACTS = 14
local MAX_GOSSIP = 4

function DialogueFacts.Build(
    record, semanticInputContext, playerUUID, activeSession
)
    local facts = {}
    local ok
    local backstoryFacts
    local workingTopicFacts
    local topicFacts
    local gossip = type(semanticInputContext) == "table"
        and semanticInputContext.npcGossip or nil
    local statements = type(gossip) == "table" and gossip.statements or nil
    local factRefs = type(gossip) == "table" and gossip.factRefs or nil
    local candidates = type(gossip) == "table" and gossip.candidates or nil
    local index
    local content
    local factID
    local candidate
    local candidateIndex
    local knowledgeSnapshot = type(semanticInputContext) == "table"
        and semanticInputContext.npcKnowledge or nil
    if Memory and type(Memory.BuildAuthorizedBackstoryFacts) == "function"
        and type(knowledgeSnapshot) == "table"
    then
        ok, backstoryFacts = pcall(
            Memory.BuildAuthorizedBackstoryFacts,
            record,
            knowledgeSnapshot,
            10,
            semanticInputContext.language
                or semanticInputContext.translationLanguage
        )
        if ok and type(backstoryFacts) == "table" then
            facts = backstoryFacts
        end
    end
    if Memory and type(Memory.BuildWorkingConversationTopicFacts) == "function"
        and type(activeSession) == "table"
    then
        ok, workingTopicFacts = pcall(
            Memory.BuildWorkingConversationTopicFacts,
            activeSession,
            8
        )
        if ok and type(workingTopicFacts) == "table"
            and workingTopicFacts[1] and #facts < MAX_FACTS
        then
            facts[#facts + 1] = workingTopicFacts[1]
        end
    end
    if Memory and type(Memory.BuildConversationTopicFacts) == "function"
        and playerUUID ~= nil
    then
        ok, topicFacts = pcall(
            Memory.BuildConversationTopicFacts,
            record,
            playerUUID,
            8
        )
        if ok and type(topicFacts) == "table" and topicFacts[1]
            and #facts < MAX_FACTS
        then
            facts[#facts + 1] = topicFacts[1]
        end
    end
    if type(statements) == "table" then
        for index = 1, math.min(
            #statements,
            MAX_GOSSIP,
            MAX_FACTS - #facts
        ) do
            content = statements[index]
            if type(content) == "string" and content ~= "" then
                factID = type(factRefs) == "table" and factRefs[index] or nil
                candidate = nil
                if type(candidates) == "table" and factID ~= nil then
                    for candidateIndex = 1, math.min(#candidates, MAX_GOSSIP) do
                        if tostring(candidates[candidateIndex].factID or "")
                            == tostring(factID)
                        then
                            candidate = candidates[candidateIndex]
                            break
                        end
                    end
                end
                facts[#facts + 1] = {
                    kind = "gossip",
                    truth_status = "reported",
                    content = content,
                    factID = factID,
                    provenance = candidate and candidate.provenance or nil,
                    confidence = candidate and candidate.confidence or nil,
                    source = gossip.source or "conversation_gossip",
                }
            end
        end
    end
    return #facts > 0 and facts or nil
end

return DialogueFacts
