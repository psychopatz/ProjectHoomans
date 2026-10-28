-- Cheap ephemeral semantic speech for routine zombie kills.
--
-- Routine kills never become relationship/conduct memories here. Meaningful
-- encounter outcomes remain owned by SocialEncounterTracker/SocialEvents.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Service = PNC.Semantics.CombatReactionService or {}
PNC.Semantics.CombatReactionService = Service
PNC.SemanticCombatReactionService = Service

local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Spatial = PNC.SpatialIndex
local Perception = PNC.Perception
local Network = PNC.Network
local Reactions = PNC.Semantics.SocialReactions
    or require "PNC/Semantics/PNC_SemanticSocialReaction"
local Profile = PNC.Semantics.CombatReactionProfile
    or require "PNC/Semantics/PNC_SemanticCombatReactionProfile"

Service.VERSION = 1
Service.REACTION_RADIUS = tonumber(Const and Const.ZOMBIE_TARGET_RADIUS) or 12
Service.MAX_PLAYER_KILL_SPEAKERS = 2
Service.MAX_NPC_KILL_LISTENERS = 2
Service.SPEAKER_COOLDOWN_MS = 5000
Service.PLAYER_REACTION_COOLDOWN_MS = 5000
Service.PlayerReactionState = Service.PlayerReactionState or {}
Service.EventSequence = tonumber(Service.EventSequence) or 0

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function coordinate(object, method, fallback)
    local value = call(object, method)
    if value == nil then value = fallback end
    return tonumber(value)
end

local function playerKey(player)
    local hooks = PNC.SocialEventHooks
    if hooks and type(hooks.ResolvePlayerKey) == "function" then
        local value = hooks.ResolvePlayerKey(player)
        if value then return tostring(value) end
    end
    local onlineID = call(player, "getOnlineID")
    local username = call(player, "getUsername")
    return "player:" .. tostring(onlineID or username or "unknown")
end

local function distanceSq(x1, y1, x2, y2)
    if Core and type(Core.DistanceSq) == "function" then
        return Core.DistanceSq(x1, y1, x2, y2)
    end
    local dx, dy = x2 - x1, y2 - y1
    return dx * dx + dy * dy
end

local function canSee(record, object)
    return Perception and type(Perception.CanSeeWorldObject) == "function"
        and Perception.CanSeeWorldObject(record, object) == true
end

local function liveBody(record)
    if not record or record.alive == false or not Registry
        or type(Registry.GetLiveZombie) ~= "function"
    then return nil end
    local body = Registry.GetLiveZombie(record.id)
    if not body or (body.isDead and body:isDead()) then return nil end
    return body
end

local function speakerReservation(record, now)
    record.runtime = record.runtime or {}
    local state = record.runtime.semanticCombatReaction
    if type(state) ~= "table" then
        state = { nextEligibleAt = 0, suppressedKills = 0, sequence = 0 }
        record.runtime.semanticCombatReaction = state
    end
    state.suppressedKills = math.min(
        99, math.max(0, math.floor(tonumber(state.suppressedKills) or 0)) + 1
    )
    if now < (tonumber(state.nextEligibleAt) or 0) then
        return false, state.suppressedKills
    end
    local burst = state.suppressedKills
    state.suppressedKills = 0
    state.nextEligibleAt = now + Service.SPEAKER_COOLDOWN_MS
    state.sequence = math.max(0, math.floor(tonumber(state.sequence) or 0)) + 1
    return true, burst, state.sequence
end

local function newEventID(record, eventType, now, sequence)
    Service.EventSequence = (tonumber(Service.EventSequence) or 0) + 1
    return table.concat({
        "semantic", tostring(eventType), tostring(record.id),
        tostring(math.floor(tonumber(now) or 0)),
        tostring(sequence or Service.EventSequence),
    }, ":")
end

local function eventFacts(eventID, eventType, record, profile, spec, burst)
    local x = tonumber(spec.x or record.x)
    local y = tonumber(spec.y or record.y)
    local z = tonumber(spec.z or record.z)
    local actorKind = tostring(spec.actorKind or "player")
    local summary
    if eventType == "zombie_kill_self" then
        summary = burst > 1
            and "the NPC killed another zombie during the fight"
            or "the NPC killed a zombie nearby"
    else
        summary = burst > 1
            and "the player killed another zombie nearby"
            or "the player killed a zombie nearby"
    end
    return {
        [eventID] = {
            eventRef = eventID,
            authoritative = true,
            disclosure = "player",
            summary = summary,
            happened = summary,
            location = x and y and { x = x, y = y, z = z or 0 } or "nearby",
            count = profile.nearbyZombieCount,
            countBand = profile.combatPressure,
            quantity = profile.quantity,
            health = profile.health,
            healthState = profile.healthState,
            nextAction = profile.nextAction,
            actorKind = actorKind,
            killBurstCount = burst,
        },
    }
end

local function ambientPayload(record, profile, eventType, eventID, facts, burst)
    local context = {
        eventType = eventType,
        eventRef = eventID,
        eventID = eventID,
        npcID = tostring(record.id),
        combatReactionRole = profile.combatReactionRole,
        combatReactionStyle = profile.combatReactionStyle,
        combatReactionMood = profile.combatReactionMood,
        combatPressure = profile.combatPressure,
        killerActorKind = profile.killerActorKind,
        relationshipState = profile.relationshipState,
        relationshipTier = profile.relationshipTier,
        socialStyle = profile.socialStyle,
        healthState = profile.healthState,
        factRefs = { eventID },
        semanticEventFacts = facts,
        killBurstCount = burst,
    }
    local realization = Reactions and type(Reactions.Resolve) == "function"
        and Reactions.Resolve({
            eventType = eventType,
            eventID = eventID,
            npcID = tostring(record.id),
            act = "REACT",
            topic = "combat",
            context = context,
        }) or nil
    if not realization or type(realization.fallback) ~= "string"
        or realization.fallback == ""
    then return nil, "semantic_realization_unavailable" end
    context.responsePlanID = realization.responsePlanID
    context.realizationFamily = realization.realizationFamily
    context.realizationID = realization.realizationID
    context.offerIDs = realization.offerIDs or {}
    return {
        source = eventType,
        eventID = eventID,
        eventRef = eventID,
        npcID = tostring(record.id),
        meaningful = false,
        transientInteraction = true,
        interactionTTLHours = 15 / 3600,
        factRefs = { eventID },
        semanticEventFacts = facts,
        offerIDs = realization.offerIDs or {},
        ambientFlavor = {
            eventID = eventID,
            eventRef = eventID,
            speechEventID = realization.realizationID,
            text = realization.fallback,
            semanticOwned = true,
            eventType = eventType,
            act = realization.semanticAct or "REACT",
            topic = realization.topic or "combat",
            responsePlanID = realization.responsePlanID,
            poolID = realization.realizationFamily,
            realizationFamily = realization.realizationFamily,
            realizationID = realization.realizationID,
            factRefs = { eventID },
            offerIDs = realization.offerIDs or {},
            semanticEventFacts = facts,
            family = "combat_kill_reaction",
            priority = 24,
            weight = 0.5,
            llmEligible = false,
            memoryEligible = false,
            npcID = tostring(record.id),
            socialRole = profile.relationshipState == "enemy"
                and "hostile" or "neutral",
            relationshipState = profile.relationshipState,
            relationshipTier = profile.relationshipTier,
            mergeKey = "combat_kill_reaction:" .. tostring(record.id),
            cooldowns = {
                familyMs = Service.SPEAKER_COOLDOWN_MS,
                speakerMs = Service.SPEAKER_COOLDOWN_MS,
                ambientMs = 2500,
                mergeWindowMs = 750,
            },
            ttlMs = 7000,
            holdMs = 1600,
            context = context,
            source = {
                kind = "semantic_speech",
                channel = "combat",
                eventType = eventType,
            },
        },
    }, nil, realization
end

local function sendReaction(player, record, profile, eventType, spec, now, burst, sequence)
    if not Network or type(Network.SendConversationRelationshipForNPC)
        ~= "function" then
        return false, "relationship_transport_unavailable"
    end
    local eventID = newEventID(record, eventType, now, sequence)
    local facts = eventFacts(eventID, eventType, record, profile, spec, burst)
    local payload, reason = ambientPayload(
        record, profile, eventType, eventID, facts, burst
    )
    if not payload then return false, reason end
    local ok, sent = pcall(
        Network.SendConversationRelationshipForNPC,
        player,
        record.id,
        eventType,
        payload
    )
    return ok and sent == true,
        ok and (sent == true and eventID or "transport_refused")
            or "transport_error"
end

local function sortedNearbyNPCs(x, y)
    if not Spatial or type(Spatial.QueryNPCs) ~= "function" then return {} end
    local rows = Spatial.QueryNPCs(x, y, Service.REACTION_RADIUS)
    rows = type(rows) == "table" and rows or {}
    table.sort(rows, function(a, b)
        local ad = distanceSq(x, y, tonumber(a.x) or x, tonumber(a.y) or y)
        local bd = distanceSq(x, y, tonumber(b.x) or x, tonumber(b.y) or y)
        if ad == bd then return tostring(a.id or "") < tostring(b.id or "") end
        return ad < bd
    end)
    return rows
end

local function sortedNearbyPlayers(x, y)
    if Spatial and type(Spatial.QueryPlayers) == "function" then
        local rows = Spatial.QueryPlayers(x, y, Service.REACTION_RADIUS)
        rows = type(rows) == "table" and rows or {}
        table.sort(rows, function(a, b)
            local ad = distanceSq(x, y,
                coordinate(a, "getX", x), coordinate(a, "getY", y))
            local bd = distanceSq(x, y,
                coordinate(b, "getX", x), coordinate(b, "getY", y))
            return ad < bd
        end)
        return rows
    end
    local rows = {}
    if Core and type(Core.ForEachPlayer) == "function" then
        Core.ForEachPlayer(function(player) rows[#rows + 1] = player end)
    end
    return rows
end

function Service.OnPlayerKill(player, zombie, spec)
    spec = type(spec) == "table" and spec or {}
    if not player or not zombie then return 0, "kill_context_invalid" end
    local x = coordinate(zombie, "getX", spec.x)
    local y = coordinate(zombie, "getY", spec.y)
    local z = coordinate(zombie, "getZ", spec.z)
    if not x or not y or not z then return 0, "kill_position_unavailable" end
    local key = playerKey(player)
    local now = tonumber(spec.now) or (Core and Core.Now and Core.Now()) or 0
    local reactionState = Service.PlayerReactionState[key]
    if type(reactionState) ~= "table" then
        reactionState = { nextEligibleAt = 0, suppressedKills = 0 }
        Service.PlayerReactionState[key] = reactionState
    end
    reactionState.suppressedKills = math.min(
        99, math.max(0,
            math.floor(tonumber(reactionState.suppressedKills) or 0)) + 1
    )
    if now < (tonumber(reactionState.nextEligibleAt) or 0) then
        return 0, "reaction_coalesced"
    end
    local globalBurst = reactionState.suppressedKills
    reactionState.suppressedKills = 0
    reactionState.nextEligibleAt =
        now + Service.PLAYER_REACTION_COOLDOWN_MS
    local radiusSq = Service.REACTION_RADIUS * Service.REACTION_RADIUS
    local emitted = 0
    for _, record in ipairs(sortedNearbyNPCs(x, y)) do
        if emitted >= Service.MAX_PLAYER_KILL_SPEAKERS then break end
        local body = liveBody(record)
        if body and math.abs((tonumber(record.z) or 0) - z) < 1
            and distanceSq(x, y, tonumber(record.x) or x,
                tonumber(record.y) or y) <= radiusSq
            and canSee(record, player) and canSee(record, zombie)
        then
            local eligible, burst, sequence = speakerReservation(record, now)
            if eligible then
                local profile = Profile.Build(record, key, {
                    role = "witness",
                    actorKind = "player",
                    inCombat = record.runtime
                        and record.runtime.target ~= nil,
                    zombieObservation = record.runtime
                        and record.runtime.zombieObservation,
                })
                local sent = sendReaction(
                    player, record, profile, "zombie_kill_witnessed",
                    { actorKind = "player", x = x, y = y, z = z },
                    now, math.max(globalBurst, burst), sequence
                )
                if sent then emitted = emitted + 1 end
            end
        end
    end
    return emitted, emitted > 0 and "semantic_reaction_emitted"
        or "no_semantic_reaction"
end

function Service.OnNPCKill(record, zombie, spec)
    spec = type(spec) == "table" and spec or {}
    if not record or record.alive == false or not zombie then
        return 0, "kill_context_invalid"
    end
    local now = tonumber(spec.now) or (Core and Core.Now and Core.Now()) or 0
    local eligible, burst, sequence = speakerReservation(record, now)
    if not eligible then return 0, "speaker_cooldown" end
    local x = coordinate(zombie, "getX", spec.x or record.x)
    local y = coordinate(zombie, "getY", spec.y or record.y)
    local z = coordinate(zombie, "getZ", spec.z or record.z)
    if not x or not y or not z then return 0, "kill_position_unavailable" end
    local radiusSq = Service.REACTION_RADIUS * Service.REACTION_RADIUS
    local listeners = 0
    local eventType = "zombie_kill_self"
    for _, player in ipairs(sortedNearbyPlayers(x, y)) do
        if listeners >= Service.MAX_NPC_KILL_LISTENERS then break end
        local px = coordinate(player, "getX")
        local py = coordinate(player, "getY")
        local pz = coordinate(player, "getZ")
        if px and py and pz and math.abs(pz - z) < 1
            and distanceSq(x, y, px, py) <= radiusSq
            and canSee(record, player)
        then
            local key = playerKey(player)
            local profile = Profile.Build(record, key, {
                role = "killer",
                actorKind = "npc",
                inCombat = true,
                zombieObservation = record.runtime
                    and record.runtime.zombieObservation,
            })
            local sent = sendReaction(
                player, record, profile, eventType,
                { actorKind = "npc", x = x, y = y, z = z },
                now, burst, sequence
            )
            if sent then listeners = listeners + 1 end
        end
    end
    return listeners, listeners > 0 and "semantic_reaction_emitted"
        or "no_listener"
end

function Service.ResetRuntime()
    Service.PlayerReactionState = {}
    Service.EventSequence = 0
end

return Service
