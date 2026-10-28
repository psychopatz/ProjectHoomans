-- Server-authoritative lifecycle adapter for already-parsed typed/headless
-- semantic input. It records meaning only; gameplay actions stay in their
-- existing domain handlers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Core = PNC.Core
local Lifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle
    or require "PNC/Semantics/PNC_SemanticInteractionLifecycle"
local Persistence = PNC.Conversation
    and PNC.Conversation.InteractionLifecyclePersistence
    or require "PNC/Conversation/PNC_InteractionLifecyclePersistence"

local function text(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if string.find(value, "%c") then return "" end
    return string.sub(value, 1, maximum or 96)
end

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function expectedReply(thread, envelope)
    local beat = thread and thread.activeBeat or nil
    if not beat or type(beat.expectedReplies) ~= "table" then return false end
    for _, value in ipairs(beat.expectedReplies) do
        value = string.upper(tostring(value or ""))
        if value == string.upper(tostring(envelope.act or "")) then
            return true
        end
    end
    return false
end

local function hasTopicStack(thread, topic)
    if not thread or not topic then return false end
    for index = #thread.topicStack, 1, -1 do
        local beat = thread.topicStack[index]
        if type(beat) == "table" and beat.topic == topic then return true end
    end
    return false
end

local function durableAct(act)
    return act == "QUESTION"
        or act == "REQUEST"
        or act == "PROMISE"
        or act == "COMMIT"
        or act == "OFFER"
end

local function rejected(requestID, npcID, reason)
    return {
        accepted = false,
        authority = "server",
        requestID = requestID,
        npcID = npcID,
        reason = reason,
    }
end

local function handle(player, args)
    args = type(args) == "table" and args or {}
    local requestID = text(args.requestID, 96)
    local npcID = text(args.npcID, 96)
    local interaction = type(args.interaction) == "table"
        and args.interaction or nil
    if not Core or type(Core.IsAuthority) ~= "function"
        or Core.IsAuthority() ~= true
    then
        return rejected(requestID, npcID, "not_authority")
    end
    if requestID == "" or npcID == "" or not interaction then
        return rejected(requestID, npcID, "interaction_identity_required")
    end
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    local authority = PNC.Conversation
        and PNC.Conversation.Authority or nil
    local validateLease = authority and authority.Internal
        and authority.Internal.ValidateLease or nil
    local valid
    local reason
    if type(validateLease) == "function" then
        valid, reason = validateLease(
            player,
            record,
            text(args.token, 128)
        )
    else
        valid = false
        reason = "conversation_authority_unavailable"
    end
    if valid ~= true then
        return rejected(requestID, npcID, reason or "invalid_conversation")
    end
    local playerKey = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetEntityKey
        and PNC.PlayerCharacters.GetEntityKey(player, {
            callback = "semantic_interaction_lifecycle",
            worldAgeHours = worldAgeHours(),
        }) or nil
    if not playerKey then
        return rejected(requestID, npcID, "player_identity_unavailable")
    end
    local projection = Persistence.Project(playerKey, npcID)
    local thread = projection and projection.thread or nil
    local beat = thread and thread.activeBeat or nil
    local provenance = beat and {
        beatID = beat.id,
        responsePlanID = beat.responsePlanID,
        flowID = beat.flowID,
        poolID = beat.poolID,
        factRefs = beat.factRefs,
    } or nil
    local envelope = Lifecycle.Envelope.Build({
        source = "typed_text",
        actorID = playerKey,
        targetID = npcID,
        playerUUID = playerKey,
        act = interaction.act or interaction.speechAct
            or interaction.intent,
        topic = interaction.topic,
        -- The client may report the already-parsed act/topic, but the
        -- server derives beat provenance from its private capsule. A client
        -- cannot invent NPC response-plan identity.
        provenance = provenance,
        modifiers = interaction.modifiers,
    })
    if not envelope then
        return rejected(requestID, npcID, "interaction_envelope_invalid")
    end
    local at = worldAgeHours()
    local options = {
        meaningful = durableAct(envelope.act),
        eventRef = "semantic:typed:" .. requestID,
        worldHour = at,
        topic = envelope.topic,
        openQuestion = envelope.act == "QUESTION"
            and envelope.topic or nil,
        commitment = (envelope.act == "PROMISE"
            or envelope.act == "COMMIT") and envelope.topic or nil,
        resolveBeat = expectedReply(thread, envelope),
        resumeTopic = thread and envelope.topic ~= nil
            and hasTopicStack(thread, envelope.topic) or false,
    }
    local applied, applyReason = Persistence.Apply(envelope, options)
    if not applied then
        return rejected(requestID, npcID, applyReason or "lifecycle_rejected")
    end
    -- The existing leased server lifecycle owns compact semantic-act markers.
    -- Client plans/relevance are not trusted or persisted: recompute admission
    -- through the same bounded providers using server-owned day/domain facts.
    local Relations = require "PNC/Semantics/PNC_SemanticInteractionRelations"
    local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
    local Resolver = require "PNC/Semantics/PNC_SemanticPragmaticResolver"
    local metadata = Relations.GetAct(envelope.act)
    local compact = Relations.GetCompactType(envelope.act)
    local markerRecorded = false
    if metadata and compact then
        local evidence = Providers.QueryEvidence({ npcID = npcID,
            playerID = playerKey, playerEntityKey = playerKey,
            worldContext = { worldAgeHours = at } }, {})
        local admission = Resolver.ResolveEvidence({ semantic = { intent = envelope.act,
            speechAct = envelope.act }, source = { actorID = playerKey }, targets = { npcID } }, evidence)
        local Events = PNC.Conversation.Memory and PNC.Conversation.Memory.Events
        if Events and (#metadata.relations.opens > 0 or admission.admitted) then
            local registered = Events.RegisterType(compact)
            if registered then
                record = PNC.Registry.Get(npcID) or record
                markerRecorded = Events.RecordRelationshipMemory(record, {
                    type = compact.id, aboutKey = playerKey,
                }, playerKey) == true
                if PNC.Relationships and type(PNC.Relationships.AddMemory) == "function" then
                    -- A zero-effect owning-domain memory records the fact of
                    -- addressing a relation, never forgiveness or permission.
                    -- Compact TODAY remains independent if this is pruned.
                    PNC.Relationships.AddMemory(npcID, playerKey, {
                        id = "semantic_marker:" .. requestID, type = compact.id,
                        aboutKey = playerKey, createdAt = at, strength = 1,
                        decayPerDay = 0.05,
                    })
                end
            end
        end
    end
    return {
        accepted = true,
        authority = "server",
        requestID = requestID,
        npcID = npcID,
        lifecycleReason = applyReason,
        persisted = applied.persisted == true,
        semanticMarkerRecorded = markerRecorded,
    }
end

Router.Register(Const.CMD_SEMANTIC_INTERACTION_LIFECYCLE, handle)

return PNC
