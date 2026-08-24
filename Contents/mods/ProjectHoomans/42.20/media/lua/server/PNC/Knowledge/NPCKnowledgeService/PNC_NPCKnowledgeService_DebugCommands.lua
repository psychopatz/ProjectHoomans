if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCKnowledge = PNC.NPCKnowledge or {}
PNC.NPCKnowledge.Internal = PNC.NPCKnowledge.Internal or {}

local Knowledge = PNC.NPCKnowledge
local Internal = Knowledge.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local PlayerCharacters = PNC.PlayerCharacters
local Relationships = PNC.Relationships
local EntityRef = PNC.EntityRef
local Definitions = PNC.KnowledgeDescriptors
local Providers = PNC.KnowledgeProviders
local Resolvers = PNC.KnowledgeResolvers
local Sources = PNC.KnowledgeEvidenceSources
local Shared = PNC.KnowledgeRegistry
local characterUUIDForPlayer = Internal.characterUUIDForPlayer
local mutableNote = Internal.mutableNote

function Knowledge.ExecuteDebugForPlayer(player, args)
    args = type(args) == "table" and args or {}
    local characterUUID, identityReason = characterUUIDForPlayer(
        player,
        "knowledge_debug_action"
    )
    local action = tostring(args.knowledgeAction or args.action or "")
    local npcID = tostring(args.npcID or "")
    local descriptorID = tostring(args.descriptorID or "")
    local result, reason
    if not characterUUID or npcID == "" then
        return nil, characterUUID and "invalid_npc_id" or identityReason
    end
    if action == "reveal" or action == "force_disclosure" then
        result, reason = Knowledge.ForceRevealForPlayer(player, npcID, descriptorID, args.worldAgeHours)
    elseif action == "discover_topic" then
        result, reason = Knowledge.DiscoverTopicForPlayer(player, npcID, args.topicID, args.worldAgeHours, "debug")
    elseif action == "forget" then
        result, reason = Knowledge.Clear(characterUUID, npcID, descriptorID)
    elseif action == "add_evidence" then
        result, reason = Knowledge.RecordEvidence({ characterUUID = characterUUID, npcID = npcID, descriptorID = descriptorID,
            sourceType = "debug", direction = args.direction, strength = args.strength, reliability = args.reliability,
            payload = args.payload, worldAgeHours = args.worldAgeHours })
    elseif action == "remove_evidence" then
        result, reason = Knowledge.RemoveEvidence(characterUUID, npcID, args.evidenceID)
    elseif action == "clear_evidence" then
        result, reason = Knowledge.Clear(characterUUID, npcID, descriptorID)
    elseif action == "recalculate" then
        result, reason = Knowledge.RecalculateDescriptor(characterUUID, npcID, descriptorID, args.worldAgeHours)
    elseif action == "validate" then
        result, reason = Knowledge.Validate(characterUUID, npcID), nil
    else
        return nil, "unsupported_knowledge_debug_action"
    end
    local snapshot = Knowledge.BuildDebugSnapshot(characterUUID, npcID, args.showTruth ~= false)
    snapshot.actionResult = result
    snapshot.actionReason = reason
    return snapshot, reason
end

function Knowledge.Validate(characterUUID, npcID)
    local note = mutableNote(characterUUID, npcID, false)
    local issues = {}
    if not note then return issues end
    for _, evidence in ipairs(note.evidence) do if not Definitions.Get(evidence.descriptorID) then issues[#issues + 1] = "orphaned_descriptor:" .. evidence.descriptorID end end
    return issues
end


return Knowledge
