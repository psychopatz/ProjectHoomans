-- First-party tier adapters for the existing InteractionProviders seam.
-- Reads only bounded session state and domain-owned query APIs.
local Adapters = {}

local function identities(context)
    local relationship = context.relationship or context.personalRelationship or {}
    local targetKey = context.playerEntityKey
    if not targetKey and relationship.targetKind and relationship.targetID then
        targetKey = tostring(relationship.targetKind) .. ":" .. tostring(relationship.targetID)
    end
    return tostring(context.playerIdentitySeed or context.playerID or "player"),
        context.npcID or context.targetNPCID, targetKey
end

function Adapters.Install(Providers)
    Providers.RegisterEvidenceAdapter({ id = "projecthoomans.session", sourceTier = "SESSION",
        Query = function(context)
            context = type(context) == "table" and context or {}
            local actorID, npcID = identities(context)
            local live = context.semanticContextState
            local snapshot = context.semanticDialogueContext or {}
            local turns = live and type(live.RecentTurns) == "function"
                and live:RecentTurns(12, true) or snapshot.recentTurns or {}
            local Relations = require "PNC/Semantics/PNC_SemanticInteractionRelations"
            local rows = {}
            for index = 1, math.min(#turns, 12) do
                local turn = turns[index]
                local metadata = Relations.GetAct(turn.speechAct or turn.intent)
                if metadata then
                    local npcSpeaker = turn.speaker == "npc"
                    rows[#rows + 1] = {
                        sourceRef = "session:" .. tostring(turn.sequence),
                        eventType = turn.speechAct or turn.intent,
                        actorID = npcSpeaker and tostring(npcID) or actorID,
                        targetID = npcSpeaker and actorID or tostring(npcID),
                        classes = metadata.classes, relations = metadata.relations,
                        retentionSalience = metadata.retentionSalience,
                        confidence = turn.confidence, sequence = turn.sequence,
                        ageHours = 0, topic = turn.topic,
                        provenance = "DialogueContextState", visibility = "direct",
                    }
                end
            end
            return rows
        end })
    Providers.RegisterEvidenceAdapter({ id = "projecthoomans.today", sourceTier = "TODAY",
        Query = function(context)
            context = type(context) == "table" and context or {}
            local actorID, npcID, targetKey = identities(context)
            local Events = PNC.Conversation and PNC.Conversation.Memory
                and PNC.Conversation.Memory.Events
            if not Events or not targetKey or not npcID then return {} end
            local record = PNC.Registry and type(PNC.Registry.Get) == "function"
                and PNC.Registry.Get(npcID) or nil
            local snapshot = context.entry and context.entry.snapshot
            record = record or { id = npcID, memory = snapshot and snapshot.memory }
            return Events.QuerySemanticEvidence(record, targetKey, actorID)
        end })
    Providers.RegisterEvidenceAdapter({ id = "projecthoomans.relationship", sourceTier = "DURABLE",
        Query = function(context)
            context = type(context) == "table" and context or {}
            local actorID, npcID, targetKey = identities(context)
            local Relationships = PNC.Relationships
            if not Relationships or type(Relationships.QuerySemanticEvidence) ~= "function"
                or not targetKey or not npcID then return {} end
            local world = context.worldContext or {}
            return Relationships.QuerySemanticEvidence(npcID, targetKey, actorID, world.worldAgeHours)
        end })
    Providers.RegisterEvidenceAdapter({ id = "projecthoomans.conduct", sourceTier = "DURABLE",
        Query = function(context)
            context = type(context) == "table" and context or {}
            local actorID, npcID, targetKey = identities(context)
            local Conduct = PNC.Conduct
            if not Conduct or type(Conduct.QuerySemanticEvidence) ~= "function"
                or not targetKey or not npcID then return {} end
            return Conduct.QuerySemanticEvidence(targetKey, "npc:" .. tostring(npcID),
                actorID, npcID, (context.worldContext or {}).worldAgeHours)
        end })
end
return Adapters
