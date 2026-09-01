-- Authority adapter for vanilla player emotes that address nearby managed NPCs.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
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
        replyFlavorID = accepted and Interactions.ReplyFlavorID(
            definition,
            before,
            {
                npcType = state.npcType,
                relationshipTier = state.relationshipTier,
                greetingState = state.greetingState,
            }
        ) or nil,
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
    local beforeRelationship = Relationships.Get
        and Relationships.Get(target.id, actorKey) or nil
    local before = relationshipSummary(
        beforeRelationship,
        beforeRelationship ~= nil,
        target.id
    )
    local npcType = Interactions.ResolveNPCType(target.record)
    local relationshipTier = Interactions.ResolveRelationshipTier(
        beforeRelationship
    )
    local greetingState = Interactions.GreetingState(
        definition,
        beforeRelationship,
        at
    )
    local cooldownActive = cooldownFor(
        beforeRelationship,
        socialDefinition,
        at
    )
    local replyFlavorID = Interactions.ReplyFlavorID(
        definition,
        beforeRelationship,
        {
            npcType = npcType,
            relationshipTier = relationshipTier,
            greetingState = greetingState,
        }
    )
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
                    playerFlavorID = definition.flavorID,
                    npcFlavorID = replyFlavorID,
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
