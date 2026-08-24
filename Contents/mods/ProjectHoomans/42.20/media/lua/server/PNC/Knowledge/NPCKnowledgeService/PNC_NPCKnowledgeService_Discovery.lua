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


function Knowledge.DiscoverAllForPlayer(
    player, npcID, at, sourceType, deferCommit
)
    local revealed = {}
    local failures = {}
    for _, descriptor in ipairs(Definitions.List()) do
        local result
        local reason
        result, reason = Knowledge.ForceRevealForPlayer(
            player, npcID, descriptor.id, at,
            sourceType or "lifelong_relationship"
        )
        if result then
            revealed[#revealed + 1] = descriptor.id
        else
            failures[#failures + 1] = descriptor.id .. ":" .. tostring(reason)
        end
    end
    if #revealed > 0 and deferCommit ~= true then
        if PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Commit then
            local committed, reason = PNC.PersistenceCoordinator.Commit(
                "lifelong_knowledge_disclosure"
            )
            if not committed then return nil, reason end
        else
            local saved, reason = Knowledge.Save()
            if saved == false and reason ~= "not_dirty" then
                return nil, reason
            end
        end
    end
    return { revealed = revealed, failures = failures }
end

-- Temporary debug counterpart to future conversational disclosures. A topic
-- only reveals descriptors the NPC would reasonably discuss in that topic;
-- it never turns the whole dossier into an omniscient dump.
function Knowledge.DiscoverTopicForPlayer(
    player, npcID, topicID, at, sourceType, deferCommit
)
    local topic = tostring(topicID or "")
    local revealed = {}
    local failures = {}
    if topic == "" then return nil, "unknown_knowledge_topic" end
    for _, descriptor in ipairs(Definitions.List()) do
        local presentation = descriptor.presentation or {}
        if tostring(presentation.topicID or "") == topic then
            local result, reason = Knowledge.ForceRevealForPlayer(player, npcID, descriptor.id, at, sourceType or "direct_disclosure")
            if result then
                revealed[#revealed + 1] = descriptor.id
            else
                failures[#failures + 1] = descriptor.id .. ":" .. tostring(reason)
            end
        end
    end
    if #revealed == 0 and #failures == 0 then return nil, "unknown_knowledge_topic" end
    -- A direct answer changes player-facing identity immediately. Commit at
    -- the disclosure boundary so learned names survive a restart even when no
    -- later periodic world save occurs.
    if #revealed > 0 and deferCommit ~= true then
        if PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Commit then
            local committed, saveReason = PNC.PersistenceCoordinator.Commit(
                "knowledge_disclosure"
            )
            if not committed then return nil, saveReason or "knowledge_save_failed" end
        else
            local saved, saveReason = Knowledge.Save()
            if saved == false and saveReason ~= "not_dirty" then
                return nil, saveReason or "knowledge_save_failed"
            end
        end
    end
    return { topicID = topic, revealed = revealed, failures = failures }
end


return Knowledge
