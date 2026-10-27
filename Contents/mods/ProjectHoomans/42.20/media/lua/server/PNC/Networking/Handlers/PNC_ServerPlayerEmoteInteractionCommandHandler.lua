-- Authority adapter for vanilla player emotes that address nearby managed NPCs.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
pcall(require, "PNC/Semantics/PNC_SemanticInteractionLifecycle")
PNC.PlayerEmoteInteractionAuthority =
    PNC.PlayerEmoteInteractionAuthority or {}

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local PlayerCharacters = PNC.PlayerCharacters
local Interactions = PNC.VanillaEmoteInteractions
local Relationships = PNC.Relationships
local RelationshipPresentation = PNC.RelationshipPresentation
local Network = PNC.Network
local Authority = PNC.PlayerEmoteInteractionAuthority
local InteractionLifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle or nil
local InteractionPersistence = PNC.Conversation
    and PNC.Conversation.InteractionLifecyclePersistence or nil
local RealizationAuthority = PNC.Semantics
    and PNC.Semantics.RealizationAuthority or nil
if not RealizationAuthority then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority"
    )
    RealizationAuthority = ok and loaded or nil
end
local CompanionSpeech = PNC.Semantics
    and PNC.Semantics.CompanionSpeech or nil
if type(CompanionSpeech) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticCompanionSpeech"
    )
    CompanionSpeech = ok and loaded or nil
end
local ContextProviders = PNC.Semantics
    and PNC.Semantics.ContextProviders or nil
if type(ContextProviders) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Core/Social/PNC_FlavorTextResolver"
    )
    ContextProviders = ok and loaded or nil
end

local MAX_REQUEST_ID = 64
local MAX_TARGETS = 8

local function text(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if string.find(value, "%c") then return "" end
    return string.sub(value, 1, maximum or MAX_REQUEST_ID)
end

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function sendResult(player, result)
    if Network and Network.SendPlayerEmoteInteractionResult then
        return Network.SendPlayerEmoteInteractionResult(player, result)
    end
    return false
end

local function rejected(player, requestID, emote, reason)
    local result = {
        requestID = requestID,
        emote = emote,
        accepted = false,
        reason = tostring(reason or "rejected"),
        targets = {},
    }
    sendResult(player, result)
    return result
end

local function liveTargets(player, definition)
    local output = {}
    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()
    local radius = tonumber(definition.radius) or 12
    local radiusSq = radius * radius
    local maxTargets = math.min(
        MAX_TARGETS,
        math.max(1, tonumber(definition.maxTargets) or MAX_TARGETS)
    )
    if not Registry or not Registry.ForEachLive then return output end
    Registry.ForEachLive(function(record, body, id)
        local x
        local y
        local z
        local dx
        local dy
        if not record or not body
            or record.alive == false
            or body.isDead and body:isDead()
        then
            return
        end
        x = body.getX and tonumber(body:getX()) or nil
        y = body.getY and tonumber(body:getY()) or nil
        z = body.getZ and tonumber(body:getZ()) or nil
        if x == nil or y == nil or z == nil then return end
        if math.floor(z) ~= math.floor(tonumber(pz) or 0) then return end
        dx = x - px
        dy = y - py
        if (dx * dx) + (dy * dy) <= radiusSq then
            output[#output + 1] = {
                id = tostring(id or record.id),
                record = record,
                body = body,
                distSq = (dx * dx) + (dy * dy),
            }
        end
    end)
    table.sort(output, function(left, right)
        if left.distSq ~= right.distSq then
            return left.distSq < right.distSq
        end
        return left.id < right.id
    end)
    while #output > maxTargets do
        table.remove(output)
    end
    return output
end

local function relationshipSummary(value, exists, npcID)
    local summary
    if RelationshipPresentation
        and RelationshipPresentation.Summarize
    then
        summary = RelationshipPresentation.Summarize(value, exists == true)
    else
        value = type(value) == "table" and value or {}
        summary = {
            exists = exists == true,
            approval = tonumber(value.approval) or 0,
            respect = tonumber(value.respect) or 0,
            familiarity = tonumber(value.familiarity) or 0,
            state = value.state,
            previousState = value.previousState,
            revision = tonumber(value.revision) or 0,
        }
    end
    summary.npcID = tostring(npcID or "")
    return summary
end

local function relationshipDelta(before, after)
    return {
        approval = (tonumber(after and after.approval) or 0)
            - (tonumber(before and before.approval) or 0),
        respect = (tonumber(after and after.respect) or 0)
            - (tonumber(before and before.respect) or 0),
        familiarity = (tonumber(after and after.familiarity) or 0)
            - (tonumber(before and before.familiarity) or 0),
    }
end

local function effectFor(socialDefinition)
    local memory = socialDefinition and socialDefinition.targetMemory or {}
    local tags = {}
    for key, value in pairs(memory.tags or {}) do
        tags[key] = value
    end
    return {
        memoryType = memory.type,
        interactionType = socialDefinition.id,
        approval = memory.approvalEffect,
        respect = memory.respectEffect,
        familiarity = memory.familiarityGain,
        morale = memory.moraleEffect,
        decayPerDay = memory.decayPerDay,
        permanent = memory.permanent == true,
        shareable = memory.shareable == true,
        tags = tags,
    }
end

local function cooldownFor(relationship, definition, at)
    local hours = tonumber(definition and definition.cooldownHours)
    local untilAt = relationship and relationship.cooldowns
        and tonumber(relationship.cooldowns[definition.id]) or nil
    if not hours or hours <= 0 or not untilAt or at >= untilAt then
        return false, nil
    end
    return true, untilAt
end

local function summaryFor(player, npcID, relationship, exists)
    local summary
    if RelationshipPresentation
        and RelationshipPresentation.BuildForConversation
    then
        summary = RelationshipPresentation.BuildForConversation(player, npcID)
    end
    return summary or relationshipSummary(relationship, exists, npcID)
end

local function buildReplyInteraction(entry, at)
    local interaction = entry and entry.interaction or nil
    local Envelope = InteractionLifecycle
        and InteractionLifecycle.Envelope or nil
    if not interaction or not Envelope
        or type(Envelope.NPCSpeech) ~= "function"
    then
        return nil
    end
    local act = string.upper(tostring(interaction.act or "REACT"))
    local replyAct = act == "GREET" and "GREET"
        or act == "FAREWELL" and "FAREWELL"
        or act == "THANK" and "ACK"
        or act == "ACK" and "ACK"
        or act == "PRAISE" and "ACK"
        or "REACT"
    local eventID = entry.eventID or entry.interactionID
    return Envelope.NPCSpeech({
        npcID = entry.npcID,
        targetID = interaction.actorID,
        playerUUID = interaction.playerUUID,
        act = replyAct,
        topic = interaction.topic or interaction.eventType,
        beatID = "beat:emote:" .. tostring(eventID or "unknown"),
        responsePlanID = entry.responsePlanID
            or "social.emote." .. tostring(interaction.eventType or "reply"),
        poolID = entry.realizationFamily,
        provenance = {
            responsePlanID = entry.responsePlanID,
            realizationFamily = entry.realizationFamily,
            realizationID = entry.realizationID,
        },
        eventType = interaction.eventType,
        eventRef = eventID,
        factRefs = entry.memoryID and { entry.memoryID } or nil,
        worldHour = at,
    })
end

local function persistInteraction(entry, at)
    if not InteractionPersistence
        or type(InteractionPersistence.Apply) ~= "function"
        or type(entry) ~= "table"
        or entry.interaction == nil
    then
        return true
    end
    local interaction = entry.interaction
    local options = {
        meaningful = true,
        eventRef = entry.eventID,
        memory = entry.memoryType,
        worldHour = at,
    }
    local projection = type(InteractionPersistence.Project) == "function"
        and InteractionPersistence.Project(
            interaction.playerUUID,
            entry.npcID
        ) or nil
    local beat = projection and projection.thread
        and projection.thread.activeBeat or nil
    if beat and type(beat.expectedReplies) == "table" then
        for _, expected in ipairs(beat.expectedReplies) do
            expected = string.upper(tostring(expected or ""))
            if expected == string.upper(tostring(interaction.act or ""))
                or expected == string.upper(
                    tostring(interaction.gesture or "")
                )
            then
                options.resolveBeat = true
                break
            end
        end
    end
    local persisted, reason = InteractionPersistence.Apply(
        interaction,
        options
    )
    if not persisted and Core and type(Core.LogWarn) == "function" then
        Core.LogWarn(
            "interaction lifecycle apply failed reason="
                .. tostring(reason or "unknown")
        )
    end
    if not persisted then return false end
    if type(InteractionPersistence.RecordNPCSpeech) == "function" then
        local replyInteraction = buildReplyInteraction(entry, at)
        if not replyInteraction then return true end
        local recorded = InteractionPersistence.RecordNPCSpeech({
            npcID = entry.npcID,
            targetID = interaction.actorID,
            playerUUID = interaction.playerUUID,
            act = replyInteraction.act,
            topic = replyInteraction.topic,
            beatID = replyInteraction.provenance.beatID,
            responsePlanID = replyInteraction.provenance.responsePlanID,
            poolID = replyInteraction.provenance.poolID,
            eventType = replyInteraction.eventType,
            eventRef = replyInteraction.eventRef,
            factRefs = replyInteraction.factRefs,
            expectedReplies = { interaction.act, "ACK", "THANK" },
            worldHour = at,
            meaningful = true,
        })
        if recorded then entry.replyInteraction = replyInteraction end
    end
    return true
end

local function targetResult(target, definition, eventID, state)
    local before = state.relationshipBefore
    local after = state.relationshipAfter
    local accepted = state.accepted == true
    return {
        npcID = target.id,
        accepted = accepted,
        applied = state.applied == true,
        reason = state.reason,
        eventID = state.applied == true and state.eventID or nil,
        interactionID = eventID,
        interactionType = definition.eventType,
        memoryID = state.memoryID,
        memoryType = state.memoryType,
        relationshipBefore = before,
        relationshipAfter = after,
        relationshipDelta = accepted and relationshipDelta(before, after)
            or nil,
        moraleDelta = state.moraleDelta or 0,
        npcType = state.npcType,
        relationshipTier = state.relationshipTier,
        greetingState = state.greetingState,
        greetingDay = state.greetingDay,
        interaction = state.interaction,
        replyInteraction = state.replyInteraction,
        resolvedText = accepted and state.resolvedText or nil,
        responsePlanID = accepted and state.responsePlanID or nil,
        realizationFamily = accepted and state.realizationFamily or nil,
        realizationID = accepted and state.realizationID or nil,
        factRefs = accepted and state.factRefs or nil,
    }
end

local function processTarget(
    player,
    actorKey,
    at,
    target,
    definition,
    socialDefinition,
    effect,
    requestID
)
    local eventID = "conversation:vanilla_emote:" .. tostring(actorKey) .. ":"
        .. requestID .. ":" .. tostring(target.id)
    local interaction
    if InteractionLifecycle
        and type(InteractionLifecycle.Envelope) == "table"
        and type(InteractionLifecycle.Envelope.Emote) == "function"
    then
        interaction = InteractionLifecycle.Envelope.Emote(
            { id = definition.id, eventType = definition.eventType },
            {
                actorID = actorKey,
                targetID = target.id,
                playerUUID = actorKey,
                worldHour = at,
            }
        )
    end
    local beforeRelationship = Relationships.Get
        and Relationships.Get(target.id, actorKey) or nil
    local before = relationshipSummary(
        beforeRelationship,
        beforeRelationship ~= nil,
        target.id
    )
    local npcType = ContextProviders and ContextProviders.ResolveNPCType
        and ContextProviders.ResolveNPCType(target.record) or "neutral"
    local relationshipTier = ContextProviders
        and ContextProviders.ResolveRelationshipTier
        and ContextProviders.ResolveRelationshipTier(beforeRelationship)
        or "reserved"
    local greetingState
    if definition.dayGate == "greeting" then
        greetingState = Interactions.HasGreetingToday
            and Interactions.HasGreetingToday(beforeRelationship, at)
            and "returning" or "first"
    end
    local cooldownActive = cooldownFor(
        beforeRelationship,
        socialDefinition,
        at
    )
    local activeBeat
    local activeProjection
    local semanticContext
    local realization
    if InteractionPersistence
        and type(InteractionPersistence.Project) == "function"
    then
        activeProjection = InteractionPersistence.Project(actorKey, target.id)
        activeBeat = activeProjection and activeProjection.thread
            and activeProjection.thread.activeBeat or nil
    end
    semanticContext = {
        action = definition.id,
        eventType = definition.eventType,
        currentTopic = activeBeat and activeBeat.topic
            or definition.eventType,
        previousTopic = activeBeat and activeBeat.topic or nil,
        relationshipState = beforeRelationship
            and beforeRelationship.state or nil,
        socialStyle = beforeRelationship
            and (beforeRelationship.state == "friend"
                or (tonumber(beforeRelationship.approval) or 0) >= 30)
            and "friendly" or nil,
        npcID = tostring(target.id or ""),
        npcType = npcType,
        relationshipTier = relationshipTier,
        greetingState = greetingState,
        renderTokens = {
            name = target.record and (target.record.name
                or target.record.displayName) or target.id,
            names = target.record and (target.record.name
                or target.record.displayName) or target.id,
        },
    }
    if not RealizationAuthority
        or type(RealizationAuthority.Resolve) ~= "function"
    then
        return {
            npcID = target.id,
            accepted = false,
            applied = false,
            reason = "semantic_realization_unavailable",
            eventID = eventID,
            interactionID = eventID,
            interactionType = definition.eventType,
            relationshipBefore = before,
            relationshipAfter = before,
            npcType = npcType,
            relationshipTier = relationshipTier,
            greetingState = greetingState,
            interaction = interaction,
        }, before
    end
    if CompanionSpeech and type(CompanionSpeech.ResolveNPCEmote) == "function" then
        realization = CompanionSpeech.ResolveNPCEmote(
            definition.id,
            semanticContext
        )
    else
        realization = RealizationAuthority.Resolve({
            poolID = "semantic.emote.reply",
            responsePlanID = "semantic.emote.reply",
            realizationFamily = "emote_reply",
            act = interaction and interaction.act or "REACT",
            topic = activeBeat and activeBeat.topic or definition.eventType,
            context = semanticContext,
            salt = eventID,
        })
    end
    if not realization then
        return {
            npcID = target.id,
            accepted = false,
            applied = false,
            reason = "semantic_emote_plan_unavailable",
            eventID = eventID,
            interactionID = eventID,
            interactionType = definition.eventType,
            relationshipBefore = before,
            relationshipAfter = before,
            npcType = npcType,
            relationshipTier = relationshipTier,
            greetingState = greetingState,
            interaction = interaction,
        }, before
    end
    if interaction then
        interaction.provenance = {
            beatID = "beat:emote:" .. tostring(eventID),
            responsePlanID = realization.responsePlanID,
            realizationFamily = realization.realizationFamily,
            realizationID = realization.realizationID,
            poolID = realization.realizationFamily,
            factRefs = realization.groundedFactRefs,
        }
    end
    local applied = false
    local reason
    local details
    local afterRelationship = beforeRelationship
    if greetingState ~= "returning" and not cooldownActive then
        applied, reason, details = Relationships.ApplyConversationEffect(
            target.id,
            actorKey,
            effect,
            {
                blockID = "vanilla_emote",
                choiceID = definition.id,
                outcomeID = requestID .. ":" .. tostring(target.id),
                eventID = eventID,
                interactionType = definition.eventType,
                worldAgeHours = at,
                interaction = {
                    kind = "player_emote",
                    source = "player_emote",
                    interactionType = definition.eventType,
                    emote = definition.id,
                    playerSpeechID = realization.realizationID,
                    npcSpeechID = realization.realizationID,
                    semanticAct = realization.semanticAct,
                    semanticTopic = realization.topic,
                    responsePlanID = realization.responsePlanID,
                    realizationFamily = realization.realizationFamily,
                    realizationID = realization.realizationID,
                    npcType = npcType,
                    relationshipTier = relationshipTier,
                    greetingState = greetingState,
                    greetingDay = Interactions.DayIndex(at),
                    applied = true,
                },
                cooldownType = tonumber(socialDefinition.cooldownHours)
                    and tonumber(socialDefinition.cooldownHours) > 0
                    and socialDefinition.id or nil,
                cooldownUntil = tonumber(socialDefinition.cooldownHours)
                    and tonumber(socialDefinition.cooldownHours) > 0
                    and at + tonumber(socialDefinition.cooldownHours)
                    or nil,
            }
        )
        if applied == true and details
            and details.relationship ~= nil
        then
            afterRelationship = details.relationship
        elseif applied == true and Relationships.Get then
            afterRelationship = Relationships.Get(target.id, actorKey)
        end
    elseif greetingState == "returning" then
        reason = "already_greeted_today"
    else
        reason = "cooldown_active"
    end
    local after = applied == true
        and summaryFor(player, target.id, afterRelationship, true)
        or before
    local entry = targetResult(target, definition, eventID, {
        accepted = applied == true
            or greetingState == "returning"
            or cooldownActive,
        applied = applied == true,
        reason = applied == true and nil or reason,
        eventID = details and details.eventID or eventID,
        memoryID = details and details.memoryID or nil,
        memoryType = details and details.memoryType
            or socialDefinition.targetMemory
                and socialDefinition.targetMemory.type or nil,
        relationshipBefore = before,
        relationshipAfter = after,
        npcType = npcType,
        relationshipTier = relationshipTier,
        greetingState = greetingState,
        greetingDay = greetingState
            and Interactions.DayIndex(at) or nil,
        interaction = interaction,
        resolvedText = realization.fallback,
        responsePlanID = realization.responsePlanID,
        realizationFamily = realization.realizationFamily,
        realizationID = realization.realizationID,
        factRefs = realization.groundedFactRefs,
        moraleDelta = applied == true
            and (tonumber(effect.morale) or 0) or 0,
    })
    return entry, after
end

function Authority.Handle(player, args)
    args = type(args) == "table" and args or {}
    local requestID = text(args and (args.requestID or args.requestId))
    local emote = text(args and (args.emote or args.emoteName), 64)
    local definition = Interactions and Interactions.Get(emote) or nil
    local at
    local actorKey
    local targets
    local result
    local entry
    local socialDefinition
    local after
    local effect
    local acceptedCount = 0
    if not Core or not Core.IsAuthority or not Core.IsAuthority() then
        return rejected(player, requestID, emote, "not_authority")
    end
    if requestID == "" then
        return rejected(player, requestID, emote, "request_id_required")
    end
    if emote == "" or not definition then
        return rejected(player, requestID, emote, "unsupported_emote")
    end
    if not player or player.isDead and player:isDead() then
        return rejected(player, requestID, emote, "player_unavailable")
    end
    if not PlayerCharacters or not PlayerCharacters.GetEntityKey then
        return rejected(player, requestID, emote, "player_identity_unavailable")
    end
    at = worldAgeHours()
    actorKey = PlayerCharacters.GetEntityKey(player, {
        callback = "player_emote_interaction",
        worldAgeHours = at,
    })
    if not actorKey then
        return rejected(player, requestID, emote, "player_identity_unavailable")
    end
    targets = liveTargets(player, definition)
    result = {
        requestID = requestID,
        emote = definition.id,
        accepted = false,
        reason = "no_npc_target",
        targets = {},
        at = at,
    }
    socialDefinition = PNC.SocialEventDefinitions
        and PNC.SocialEventDefinitions[definition.eventType] or nil
    if not socialDefinition or not Relationships
        or not Relationships.ApplyConversationEffect
    then
        result.reason = "relationship_service_unavailable"
        sendResult(player, result)
        return result
    end
    effect = effectFor(socialDefinition)
    for _, targetValue in ipairs(targets) do
        entry, after = processTarget(
            player,
            actorKey,
            at,
            targetValue,
            definition,
            socialDefinition,
            effect,
            requestID
        )
        result.targets[#result.targets + 1] = entry
        if entry.accepted == true then
            acceptedCount = acceptedCount + 1
            result.eventID = result.eventID or entry.eventID
            if entry.applied == true then
                persistInteraction(entry, at)
            elseif entry.interaction then
                -- A cooldown/no-op emote still receives the authored reply,
                -- but must not materialize a durable pair capsule. Carry the
                -- semantic reply beat only through the private result.
                entry.replyInteraction = buildReplyInteraction(entry, at)
            end
            if Network and Network.SendConversationRelationship then
                Network.SendConversationRelationship(
                    player,
                    after,
                    "player_emote",
                    {
                        source = "player_emote",
                        npcID = entry.npcID,
                        eventID = entry.eventID,
                        relationshipBefore = entry.relationshipBefore,
                        relationshipAfter = entry.relationshipAfter,
                        relationshipDelta = entry.relationshipDelta,
                    }
                )
            end
        end
    end
    result.accepted = acceptedCount > 0
    if result.accepted then
        result.reason = nil
    elseif #result.targets > 0 then
        result.reason = result.targets[1].reason
    end
    sendResult(player, result)
    return result
end

Router.Register(Const.CMD_PLAYER_EMOTE_INTERACTION, function(player, args)
    Authority.Handle(player, args)
end)

return Authority
