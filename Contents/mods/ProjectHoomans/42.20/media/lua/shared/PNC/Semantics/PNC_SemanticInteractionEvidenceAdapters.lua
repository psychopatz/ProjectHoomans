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
    for _, sourceTier in ipairs({ "TODAY", "DURABLE" }) do
        local tier = sourceTier
        Providers.RegisterEvidenceAdapter({ id = "projecthoomans.remote_" .. string.lower(tier),
            sourceTier = tier, Query = function(context)
                context = type(context) == "table" and context or {}
                -- Local owning APIs take precedence. Remote rows are only the
                -- existing player-scoped presentation, never client authority.
                if tier == "DURABLE" and PNC.Relationships
                    and type(PNC.Relationships.QuerySemanticEvidence) == "function" then return {} end
                local record = context.npcID and PNC.Registry and PNC.Registry.Get
                    and PNC.Registry.Get(context.npcID)
                local authoritative = PNC.Core and type(PNC.Core.IsAuthority) == "function"
                    and PNC.Core.IsAuthority() == true
                if tier == "TODAY" and authoritative and record and record.memory then return {} end
                local snapshot = context.relationship and context.relationship.semanticEvidence
                if type(snapshot) ~= "table" then return {} end
                local at = (context.worldContext or {}).worldAgeHours
                local observed = tonumber(snapshot.observedWorldAgeHours)
                if not observed or not tonumber(at) then return {} end
                local elapsed = tonumber(at) - observed
                if elapsed < 0 or elapsed > 1 then return {} end
                local Events = PNC.Conversation and PNC.Conversation.Memory
                    and PNC.Conversation.Memory.Events
                if tier == "TODAY" and (not Events
                    or snapshot.observedWorldDay ~= Events.Internal.CurrentWorldDay()) then return {} end
                local rows = {}
                for index = 1, math.min(#(snapshot.rows or {}), 16) do
                    local value = snapshot.rows[index]
                    if type(value) == "table" and value.sourceTier == tier then
                        local row = Providers.NormalizeEvidence(value, value.providerID, tier)
                        if row then
                            row.ageHours = (row.ageHours or 0) + elapsed
                            rows[#rows + 1] = row
                        end
                    end
                end
                return rows
            end })
    end
    Providers.RegisterEvidenceAdapter({
        id = "projecthoomans.zombie_observation",
        sourceTier = "SESSION",
        Query = function(context, query)
            context = type(context) == "table" and context or {}
            local observation = type(context.zombieObservation) == "table"
                and context.zombieObservation or nil
            local count = observation
                and math.max(0, tonumber(observation.hordeCount
                    or observation.nearbyCount) or 0) or 0
            if not observation or count <= 0 then return {} end
            return {
                {
                    sourceRef = "runtime:zombie_pressure:"
                        .. tostring(observation.band or "unknown"),
                    eventType = "zombie_pressure_current",
                    actorID = tostring(context.npcID or context.targetNPCID or "npc"),
                    classes = { "world_danger", "zombie_pressure" },
                    relations = {},
                    tags = {
                        tostring(observation.band or "unknown"),
                        observation.tacticalHorde == true
                            and "tactical_horde" or "local_pressure",
                    },
                    retentionSalience = 0,
                    confidence = 1,
                    effectiveStrength = math.min(1, count / 12),
                    ageHours = 0,
                    topic = "combat",
                    visibility = "direct",
                    provenance = "ZombieObservation",
                },
            }
        end,
    })
    Providers.RegisterEvidenceAdapter({ id = "projecthoomans.session", sourceTier = "SESSION",
        Query = function(context, query)
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
            local pending = live and type(live.GetPendingFollowUp) == "function"
                and live:GetPendingFollowUp() or snapshot.pendingFollowUp or context.pendingFollowUp
            if type(pending) == "table" and pending.status ~= "closed" then
                local metadata = Relations.GetAct(string.upper(tostring(pending.kind or "")))
                if metadata then
                    rows[#rows + 1] = { sourceRef = "pending:" .. tostring(pending.id or pending.kind),
                        actorID = tostring(npcID), targetID = actorID,
                        relations = metadata.relations, classes = metadata.classes,
                        confidence = 1, ageHours = 0, sequence = pending.openedTurn,
                        topic = pending.topic, provenance = "DialogueContextState.pendingFollowUp" }
                end
            end
            local response = context.dialogueDecision and context.dialogueDecision.response
            local plan = response and response.plan
            local metadata = type(plan) == "table" and Relations.GetAct(plan.dialogueAct)
            if metadata then
                rows[#rows + 1] = { sourceRef = "session:npc_response",
                    actorID = tostring(npcID), targetID = actorID,
                    relations = metadata.relations, classes = metadata.classes,
                    confidence = 1, ageHours = 0, topic = plan.topic,
                    provenance = "ResponseChannel.UtterancePlan" }
            end
            return rows
        end })
    Providers.RegisterEvidenceAdapter({ id = "projecthoomans.today", sourceTier = "TODAY",
        Query = function(context, query)
            context = type(context) == "table" and context or {}
            local authoritative = PNC.Core and type(PNC.Core.IsAuthority) == "function"
                and PNC.Core.IsAuthority() == true
            if not authoritative and context.relationship and context.relationship.semanticEvidence then return {} end
            local actorID, npcID, targetKey = identities(context)
            local Events = PNC.Conversation and PNC.Conversation.Memory
                and PNC.Conversation.Memory.Events
            if not Events or not targetKey or not npcID then return {} end
            local record = PNC.Registry and type(PNC.Registry.Get) == "function"
                and PNC.Registry.Get(npcID) or nil
            local snapshot = context.entry and context.entry.snapshot
            record = record or { id = npcID, memory = snapshot and snapshot.memory }
            return Events.QuerySemanticEvidence(record, targetKey, actorID, query)
        end })
    Providers.RegisterEvidenceAdapter({ id = "projecthoomans.relationship", sourceTier = "DURABLE",
        Query = function(context, query)
            context = type(context) == "table" and context or {}
            local actorID, npcID, targetKey = identities(context)
            local Relationships = PNC.Relationships
            if not Relationships or type(Relationships.QuerySemanticEvidence) ~= "function"
                or not targetKey or not npcID then return {} end
            local world = context.worldContext or {}
            return Relationships.QuerySemanticEvidence(npcID, targetKey, actorID, world.worldAgeHours, query)
        end })
    Providers.RegisterEvidenceAdapter({ id = "projecthoomans.conduct", sourceTier = "DURABLE",
        Query = function(context, query)
            context = type(context) == "table" and context or {}
            local actorID, npcID, targetKey = identities(context)
            local Conduct = PNC.Conduct
            if not Conduct or type(Conduct.QuerySemanticEvidence) ~= "function"
                or not targetKey or not npcID then return {} end
            return Conduct.QuerySemanticEvidence(targetKey, "npc:" .. tostring(npcID),
                actorID, npcID, (context.worldContext or {}).worldAgeHours, query)
        end })
end
return Adapters
