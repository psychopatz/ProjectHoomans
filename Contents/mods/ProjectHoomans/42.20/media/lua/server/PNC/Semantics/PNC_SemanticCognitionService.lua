-- Authoritative NPC-cognition storage and conversation projection.
--
-- The service is deliberately smaller than the NLU layer.  It records facts
-- supplied by perception, communication, or authored gameplay systems and
-- exposes only a bounded, conversation-scoped projection to a client.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Projection = PNC.Semantics.CognitionProjection
    or require "PNC/Semantics/PNC_SemanticCognitionProjection"
local Service = PNC.Semantics.CognitionService or {}
PNC.Semantics.CognitionService = Service

local Core = PNC.Core
local Registry = PNC.Registry
local Memory = PNC.Semantics.ConversationMemoryProvider
if type(Memory) ~= "table" then
    Memory = require
        "PNC/Semantics/PNC_SemanticConversationMemoryProvider"
end
if type(Memory) ~= "table" then Memory = nil end
local MemoryEvents = Memory and Memory.Events or nil
local WorldKnowledge = PNC.WorldKnowledge

Service.VERSION = 1
Service.MAX_LIVE_FACT_PROVIDERS = 8
Service.LiveFactProviders = Service.LiveFactProviders or {}
Service.LiveFactProvidersByID = Service.LiveFactProvidersByID or {}

local function liveFactProviderSupports(provider, subject)
    local subjects = provider and provider.subjects
    return type(subjects) ~= "table" or subjects[subject] == true
end

local function sortLiveFactProviders()
    table.sort(Service.LiveFactProviders, function(left, right)
        local leftPriority = tonumber(left.priority) or 0
        local rightPriority = tonumber(right.priority) or 0
        if leftPriority == rightPriority then
            return left.id < right.id
        end
        return leftPriority > rightPriority
    end)
end

function Service.RegisterLiveFactProvider(id, provider, priority)
    local existing
    local entry
    local index
    id = tostring(id or "")
    if id == "" or #id > 96
        or string.find(id, "[^%w_%.%-]")
        or type(provider) ~= "table"
        or type(provider.Resolve) ~= "function"
    then
        return false, "invalid_live_fact_provider"
    end
    existing = Service.LiveFactProvidersByID[id]
    entry = {
        id = id,
        provider = provider,
        priority = tonumber(priority or provider.priority) or 0,
        subjects = provider.subjects,
    }
    Service.LiveFactProvidersByID[id] = entry
    if existing then
        for index = 1, #Service.LiveFactProviders do
            if Service.LiveFactProviders[index] == existing then
                Service.LiveFactProviders[index] = entry
                sortLiveFactProviders()
                return true, "live_fact_provider_replaced"
            end
        end
    end
    if #Service.LiveFactProviders >= Service.MAX_LIVE_FACT_PROVIDERS then
        Service.LiveFactProvidersByID[id] = existing
        return false, "live_fact_provider_limit"
    end
    Service.LiveFactProviders[#Service.LiveFactProviders + 1] = entry
    sortLiveFactProviders()
    return true, "live_fact_provider_registered"
end

function Service.UnregisterLiveFactProvider(id)
    local entry = Service.LiveFactProvidersByID[tostring(id or "")]
    local index
    if not entry then return false end
    for index = #Service.LiveFactProviders, 1, -1 do
        if Service.LiveFactProviders[index] == entry then
            table.remove(Service.LiveFactProviders, index)
            break
        end
    end
    Service.LiveFactProvidersByID[tostring(id or "")] = nil
    return true
end

local function liveFactsFor(record, player, options)
    local output = {}
    local subject = tostring(options and options.subject or "")
    local providerOptions = {}
    local viewer
    local index
    local entry
    local fact
    local reason
    if subject == "" then return output end
    for key, value in pairs(type(options) == "table" and options or {}) do
        providerOptions[key] = value
    end
    viewer = providerOptions.viewer
    if type(viewer) ~= "table" then
        viewer = {}
        if PNC.Factions
            and type(PNC.Factions.GetPlayerFaction) == "function"
        then
            local faction = PNC.Factions.GetPlayerFaction(player)
            if type(faction) == "table" and faction.id then
                viewer.factionID = faction.id
                viewer.homeFactionID = faction.id
            end
        end
        providerOptions.viewer = viewer
    end
    for index = 1, #Service.LiveFactProviders do
        entry = Service.LiveFactProviders[index]
        if liveFactProviderSupports(entry.provider, subject) then
            fact, reason = entry.provider.Resolve(
                record, player, providerOptions)
            if type(fact) == "table" then
                fact.subject = fact.subject or subject
                output[#output + 1] = fact
                break
            end
        end
    end
    return output
end

local function authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function resolveRecord(npcID)
    local id = tostring(npcID or "")
    local record
    if id == "" or not Registry or not Registry.Get then
        return nil, "npc_id_required"
    end
    record = Registry.Get(id)
    if type(record) ~= "table" or tostring(record.id or "") ~= id then
        return nil, "npc_not_found"
    end
    if record.alive == false then return nil, "npc_unavailable" end
    return record
end

local function storeFor(record)
    if not record then return nil end
    -- Service writes and record loading both normalize this table; keep read
    -- paths from deep-copying and sorting it again on every lookup.
    if type(record.semanticCognition) == "table"
        and record.semanticCognition.schemaVersion == Projection.VERSION
        and tostring(record.semanticCognition.npcID or "")
            == tostring(record.id or "")
        and type(record.semanticCognition.facts) == "table"
    then
        return record.semanticCognition
    end
    record.semanticCognition = Projection.Normalize(
        record.semanticCognition,
        record.id
    )
    return record.semanticCognition
end

local function requestOptions(args)
    args = type(args) == "table" and args or {}
    local output = {
        subject = args.subject,
        targetID = args.targetID or args.target,
        subjects = args.subjects,
    }
    return output
end

local function currentPlayerKey(player)
    local PlayerCharacters = PNC.PlayerCharacters
    local ok
    local key
    if not player or not PlayerCharacters
        or type(PlayerCharacters.GetEntityKey) ~= "function"
    then
        return nil
    end
    ok, key = pcall(
        PlayerCharacters.GetEntityKey,
        player,
        { callback = "semantic_cognition_gossip" }
    )
    if not ok or type(key) ~= "string" or key == "" then
        return nil
    end
    return key
end

local function currentPlayerName(player)
    local name
    if not player then return nil end
    if type(player.getUsername) == "function" then
        name = player:getUsername()
        if type(name) == "string" and name ~= "" then
            return name
        end
    end
    if type(player.getDisplayName) == "function" then
        name = player:getDisplayName()
        if type(name) == "string" and name ~= "" then
            return name
        end
    end
    return nil
end

local function attachMemoryGossip(projection, speakerRecord, options, player)
    local targetValue = options.targetID or options.target
    local target
    local subjectName
    local codes
    local selfQuery = tostring(targetValue or "") == "self"
    if WorldKnowledge and type(WorldKnowledge.BuildConversationContext) == "function" then
        local context = WorldKnowledge.BuildConversationContext(speakerRecord, {
            language = options.language,
            max = MemoryEvents and MemoryEvents.MAX_GOSSIP or 4,
        })
        if context and context.npcGossip
            and type(context.npcGossip.statements) == "table"
            and #context.npcGossip.statements > 0
        then
            projection._worldKnowledgeGossip = {
                subject = "world",
                statements = context.npcGossip.statements,
                factRefs = context.npcGossip.factRefs,
                candidates = context.worldKnowledge
                    and context.worldKnowledge.candidates or nil,
            }
            return
        end
    end
    if not projection or not MemoryEvents
        or type(MemoryEvents.ResolveTarget) ~= "function"
        or type(MemoryEvents.BuildGossipCodes) ~= "function"
    then
        return
    end
    if selfQuery then
        targetValue = currentPlayerKey(player)
        target = targetValue
            and MemoryEvents.ResolveTarget(targetValue) or nil
        subjectName = target and target.kind == "player"
            and (currentPlayerName(player) or "you")
            or target and target.record and target.record.name or nil
        if target and type(subjectName) == "string" and subjectName ~= "" then
            codes = MemoryEvents.BuildGossipCodes(
                speakerRecord,
                target,
                subjectName,
                speakerRecord.tacticalClass,
                MemoryEvents.MAX_GOSSIP
            )
        end
    else
        target = MemoryEvents.ResolveTarget(targetValue)
        subjectName = target and target.record and target.record.name or nil
        if target and type(subjectName) == "string" and subjectName ~= "" then
            codes = MemoryEvents.BuildGossipCodes(
                speakerRecord,
                target,
                subjectName,
                speakerRecord.tacticalClass,
                MemoryEvents.MAX_GOSSIP
            )
        end
    end
    if selfQuery and (type(codes) ~= "table" or #codes == 0) then
        local EntityRef = PNC.EntityRef
        local selfTargetKey = EntityRef and EntityRef.ForNPC
            and EntityRef.ForNPC(speakerRecord.id) or nil
        local selfTarget = selfTargetKey
            and MemoryEvents.ResolveTarget(selfTargetKey) or nil
        local selfName = selfTarget and selfTarget.record
            and selfTarget.record.name or speakerRecord.name or "me"
        if selfTarget and type(selfName) == "string" and selfName ~= "" then
            codes = MemoryEvents.BuildGossipCodes(
                speakerRecord,
                selfTarget,
                selfName,
                speakerRecord.tacticalClass,
                MemoryEvents.MAX_GOSSIP
            )
            subjectName = selfName
        end
    end
    if type(codes) == "table" and #codes > 0 then
        projection._memoryGossip = {
            codes = codes,
            subject = subjectName,
        }
    end
end

function Service.Get(npcID)
    if not authority() then return nil, "not_authority" end
    local record, reason = resolveRecord(npcID)
    if not record then return nil, reason end
    return storeFor(record)
end

function Service.GetFact(npcID, factSubject, targetID, worldAgeHours)
    local projection, reason = Service.Get(npcID)
    if not projection then return nil, reason end
    return Projection.Get(
        projection,
        factSubject,
        targetID,
        worldAgeHours
    )
end

-- Perception and communication systems call this method after they have
-- established the evidence.  Cognition never scans the world or performs an
-- action on its own.
function Service.Remember(npcID, factSpec)
    if not authority() then return false, "not_authority" end
    local record, reason = resolveRecord(npcID)
    local projection
    local accepted
    local result
    if not record then return false, reason end
    if type(factSpec) ~= "table" then return false, "invalid_fact" end
    projection = storeFor(record)
    accepted, result, projection = Projection.Upsert(
        projection,
        factSpec,
        record.id
    )
    if not accepted then return false, result end
    record.semanticCognition = projection
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "semantic_cognition")
    end
    return true, result, projection
end

function Service.Forget(npcID, factSubject, targetID)
    if not authority() then return false, "not_authority" end
    local record, reason = resolveRecord(npcID)
    local accepted
    local result
    local projection
    if not record then return false, reason end
    projection = storeFor(record)
    accepted, result, projection = Projection.Remove(
        projection,
        factSubject,
        targetID,
        record.id
    )
    if not accepted then return false, result end
    record.semanticCognition = projection
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "semantic_cognition")
    end
    return true, result, projection
end

function Service.BuildProjection(npcID, options)
    if not authority() then return nil, "not_authority" end
    local record, reason = resolveRecord(npcID)
    if not record then return nil, reason end
    return Projection.BuildClientProjection(
        storeFor(record),
        record.id,
        options
    )
end

function Service.BuildForConversation(player, npcID, options)
    local record
    local reason
    local valid
    local projection
    local request
    options = type(options) == "table" and options or {}
    if not authority() then return nil, "not_authority" end
    record, reason = resolveRecord(npcID)
    if not record then return nil, reason end
    if not PNC.ConversationScene
        or not PNC.ConversationScene.ValidateConversationLease
    then
        return nil, "conversation_authority_unavailable"
    end
    valid, reason = PNC.ConversationScene.ValidateConversationLease(
        record,
        player,
        options.conversationToken or options.token
    )
    if valid ~= true then return nil, reason or "invalid_conversation" end
    request = requestOptions(options)
    request.ephemeralFacts = liveFactsFor(record, player, options)
    projection = Projection.BuildClientProjection(
        storeFor(record),
        record.id,
        request
    )
    if projection then
        local identity = type(record.identity) == "table"
            and record.identity or nil
        projection.identitySeed = record.identitySeed
            or identity and (identity.identitySeed or identity.seed)
        attachMemoryGossip(projection, record, options, player)
    end
    return projection
end

function Service.HandleRequest(player, args)
    local projection
    local reason
    local Network = PNC.Network
    args = type(args) == "table" and args or {}
    projection, reason = Service.BuildForConversation(
        player,
        args.npcID,
        args
    )
    if Network and Network.SendSemanticCognition then
        Network.SendSemanticCognition(
            player,
            projection,
            reason,
            args.requestID,
            args.npcID,
            args.targetID
        )
    end
    return projection ~= nil, reason, projection
end

return Service
