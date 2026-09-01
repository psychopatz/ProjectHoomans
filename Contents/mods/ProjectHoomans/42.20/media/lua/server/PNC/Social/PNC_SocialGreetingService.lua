-- Server-authoritative daily NPC greeting service.
--
-- Proximity is only a trigger. Relationship mutation remains inside the
-- canonical relationship service and presentation uses the same relationship
-- transport as gifts, LLM reactions, treatment, and player emotes.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.SocialGreeting = PNC.SocialGreeting or {}
PNC.SocialGreeting.Internal = PNC.SocialGreeting.Internal or {}

local Service = PNC.SocialGreeting
local Internal = Service.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Spatial = PNC.SpatialIndex
local PlayerCharacters = PNC.PlayerCharacters
local Interactions = PNC.VanillaEmoteInteractions
local Relationships = PNC.Relationships
local Presentation = PNC.RelationshipPresentation
local Network = PNC.Network

Service.PUMP_INTERVAL_HOURS = 1 / 3600
Service.GREETING_RADIUS = 10
Service.RESET_RADIUS = 14
Service.MAX_GREETING_EVENTS_PER_PLAYER = 4
Service.LastPumpAt = Service.LastPumpAt
Service.PresenceByPlayer = Service.PresenceByPlayer or {}

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

local function worldAgeHours(value)
    value = finite(value, nil)
    if value ~= nil then return math.max(0, value) end
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            finite(getGameTime():getWorldAgeHours(), 0)
        )
    end
    return 0
end

local function playerKey(player)
    local key
    if PlayerCharacters and PlayerCharacters.GetEntityKey then
        key = PlayerCharacters.GetEntityKey(player, {
            callback = "social_greeting",
            worldAgeHours = worldAgeHours(),
        })
        if key then return tostring(key) end
    end
    if player and player.getUsername then
        key = player:getUsername()
        if key and tostring(key) ~= "" then return tostring(key) end
    end
    if player and player.getOnlineID then
        key = player:getOnlineID()
        if key ~= nil then return tostring(key) end
    end
    return tostring(player or "")
end

local function liveBody(id)
    local body = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(id) or nil
    if not body then return nil end
    if body.isDead and body:isDead() then return nil end
    return body
end

local function bodyPosition(body, record)
    local x = body and body.getX and tonumber(body:getX())
        or tonumber(record and record.x)
    local y = body and body.getY and tonumber(body:getY())
        or tonumber(record and record.y)
    local z = body and body.getZ and tonumber(body:getZ())
        or tonumber(record and record.z)
    if x == nil or y == nil or z == nil then return nil end
    return x, y, z
end

local function relationshipSummary(value, exists, npcID)
    local summary
    if Presentation and Presentation.Summarize then
        summary = Presentation.Summarize(value, exists == true)
    else
        value = type(value) == "table" and value or {}
        summary = {
            exists = exists == true,
            approval = finite(value.approval, 0),
            respect = finite(value.respect, 0),
            familiarity = finite(value.familiarity, 0),
            state = value.state,
            previousState = value.previousState,
            revision = math.max(0, math.floor(finite(value.revision, 0))),
        }
    end
    summary.npcID = tostring(npcID or "")
    return summary
end

local function relationshipDelta(before, after)
    return {
        approval = finite(after and after.approval, 0)
            - finite(before and before.approval, 0),
        respect = finite(after and after.respect, 0)
            - finite(before and before.respect, 0),
        familiarity = finite(after and after.familiarity, 0)
            - finite(before and before.familiarity, 0),
    }
end

local function effectFor(definition)
    local memory = definition and definition.targetMemory or {}
    local tags = {}
    for key, value in pairs(memory.tags or {}) do tags[key] = value end
    return {
        memoryType = memory.type,
        interactionType = definition and definition.id,
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

local function nearbyTargets(player)
    local output = {}
    local seen = {}
    local px = player and player.getX and tonumber(player:getX()) or nil
    local py = player and player.getY and tonumber(player:getY()) or nil
    local pz = player and player.getZ and tonumber(player:getZ()) or nil
    local radius = Service.RESET_RADIUS
    local radiusSq = radius * radius
    local function add(record, id)
        local body
        local x
        local y
        local z
        local dx
        local dy
        id = tostring(id or record and record.id or "")
        if id == "" or seen[id] or not record then return end
        body = liveBody(id)
        if not body then return end
        x, y, z = bodyPosition(body, record)
        if x == nil or y == nil or z == nil then return end
        if math.floor(z) ~= math.floor(pz or 0) then return end
        dx = x - px
        dy = y - py
        if dx * dx + dy * dy <= radiusSq then
            seen[id] = true
            output[#output + 1] = {
                id = id,
                record = record,
                body = body,
                x = x,
                y = y,
                z = z,
                distSq = dx * dx + dy * dy,
            }
        end
    end
    if px == nil or py == nil or pz == nil then return output end
    if Spatial and Spatial.QueryNPCs then
        for _, record in ipairs(Spatial.QueryNPCs(px, py, radius) or {}) do
            add(record, record and record.id)
        end
    elseif Registry and Registry.ForEachLive then
        Registry.ForEachLive(function(record, _, id)
            add(record, id)
        end)
    end
    table.sort(output, function(left, right)
        if left.distSq ~= right.distSq then
            return left.distSq < right.distSq
        end
        return left.id < right.id
    end)
    return output
end

local function stateFor(key)
    local state = Service.PresenceByPlayer[key]
    if not state then
        state = { inside = {} }
        Service.PresenceByPlayer[key] = state
    end
    return state
end

function Service.Reset()
    Service.LastPumpAt = nil
    Service.PresenceByPlayer = {}
end

function Service.TryGreet(player, target, at, actorKey)
    local npcID = tostring(target and target.id or "")
    local record = target and target.record or nil
    local relationship
    local npcType
    local tier
    local day
    local eventID
    local definition
    local applied
    local reason
    local details
    local afterRelationship
    local before
    local after
    local delta
    local greetingState
    local flavorID
    if npcID == "" or not record or not player then
        return false, "invalid_target"
    end
    if player.isDead and player:isDead() then
        return false, "player_unavailable"
    end
    actorKey = tostring(actorKey or playerKey(player))
    at = worldAgeHours(at)
    relationship = Relationships and Relationships.Get
        and Relationships.Get(npcID, actorKey) or nil
    npcType = Interactions and Interactions.ResolveNPCType
        and Interactions.ResolveNPCType(record) or "neutral"
    if not Interactions
        or not Interactions.IsAutomaticGreetingEligible
        or not Interactions.IsAutomaticGreetingEligible(
            relationship,
            npcType
        )
    then
        return false, "relationship_not_eligible"
    end
    if Interactions.HasGreetingToday
        and Interactions.HasGreetingToday(relationship, at)
    then
        return false, "already_greeted_today"
    end
    definition = PNC.SocialEventDefinitions
        and PNC.SocialEventDefinitions.npc_proximity_greeting or nil
    if not definition or not Relationships
        or not Relationships.ApplyConversationEffect
    then
        return false, "relationship_service_unavailable"
    end
    day = Interactions.DayIndex(at)
    greetingState = "first"
    tier = Interactions.ResolveRelationshipTier(relationship)
    flavorID = Interactions.GreetingReplyFlavorID(
        npcType,
        tier,
        greetingState
    )
    eventID = "conversation:proximity_greeting:" .. actorKey .. ":"
        .. npcID .. ":day:" .. tostring(day)
    before = relationshipSummary(relationship, true, npcID)
    applied, reason, details = Relationships.ApplyConversationEffect(
        npcID,
        actorKey,
        effectFor(definition),
        {
            blockID = "social_greeting",
            choiceID = "proximity_greeting",
            outcomeID = actorKey .. ":" .. npcID .. ":" .. tostring(day),
            eventID = eventID,
            interactionType = definition.id,
            worldAgeHours = at,
            sourceSystem = "proximity_greeting",
            interaction = {
                kind = "npc_proximity_greeting",
                source = "proximity_greeting",
                interactionType = definition.id,
                npcFlavorID = flavorID,
                npcType = npcType,
                relationshipTier = tier,
                greetingState = greetingState,
                greetingDay = day,
                applied = true,
            },
        }
    )
    if applied ~= true then return false, reason or "not_applied" end
    afterRelationship = details and details.relationship or nil
    if not afterRelationship and Relationships.Get then
        afterRelationship = Relationships.Get(npcID, actorKey)
    end
    after = relationshipSummary(afterRelationship, true, npcID)
    delta = relationshipDelta(before, after)
    if Network and Network.SendConversationRelationshipForNPC then
        Network.SendConversationRelationshipForNPC(
            player,
            npcID,
            "proximity_greeting",
            {
                source = "proximity_greeting",
                eventID = details and details.eventID or eventID,
                relationshipBefore = before,
                relationshipAfter = after,
                relationshipDelta = delta,
                npcID = npcID,
            }
        )
    end
    if Network and Network.SendSocialGreeting then
        Network.SendSocialGreeting(player, {
            eventID = details and details.eventID or eventID,
            npcID = npcID,
            flavorID = flavorID,
            npcType = npcType,
            relationshipTier = tier,
            greetingState = greetingState,
            greetingDay = day,
            relationshipBefore = before,
            relationshipAfter = after,
            relationshipDelta = delta,
            applied = true,
            memoryID = details and details.memoryID or nil,
            memoryType = details and details.memoryType
                or definition.targetMemory.type,
            interactionType = definition.id,
        })
    end
    return true, {
        npcID = npcID,
        eventID = details and details.eventID or eventID,
        flavorID = flavorID,
        npcType = npcType,
        relationshipTier = tier,
        greetingState = greetingState,
        greetingDay = day,
        relationshipBefore = before,
        relationshipAfter = after,
        relationshipDelta = delta,
        applied = true,
        memoryID = details and details.memoryID or nil,
        memoryType = details and details.memoryType
            or definition.targetMemory.type,
        interactionType = definition.id,
    }
end

function Service.Pump(occurredAt)
    local emitted = 0
    local now = worldAgeHours(occurredAt)
    if not Core or not Core.IsAuthority or not Core.IsAuthority() then
        return 0
    end
    if Service.LastPumpAt
        and now - Service.LastPumpAt < Service.PUMP_INTERVAL_HOURS
    then
        return 0
    end
    Service.LastPumpAt = now
    if not Core.ForEachPlayer then return 0 end
    Core.ForEachPlayer(function(player)
        local key = playerKey(player)
        local state = stateFor(key)
        local targets = nearbyTargets(player)
        local seen = {}
        local attempts = 0
        for _, target in ipairs(targets) do
            local inside = target.distSq <= Service.GREETING_RADIUS
                * Service.GREETING_RADIUS
            seen[target.id] = true
            if not inside then
                if target.distSq > Service.RESET_RADIUS
                    * Service.RESET_RADIUS
                then
                    state.inside[target.id] = false
                end
            elseif state.inside[target.id] ~= true then
                if attempts < Service.MAX_GREETING_EVENTS_PER_PLAYER then
                    state.inside[target.id] = true
                    local ok = Service.TryGreet(player, target, now, key)
                    if ok then
                        emitted = emitted + 1
                        attempts = attempts + 1
                    end
                else
                    -- Leave the edge pending so a dense group is drained over
                    -- later pumps instead of making a single-frame chorus.
                    state.inside[target.id] = false
                end
            end
        end
        for npcID, _ in pairs(state.inside) do
            if not seen[npcID] then state.inside[npcID] = false end
        end
    end)
    return emitted
end

Internal.WorldAgeHours = worldAgeHours
Internal.NearbyTargets = nearbyTargets
Internal.PlayerKey = playerKey

return Service
