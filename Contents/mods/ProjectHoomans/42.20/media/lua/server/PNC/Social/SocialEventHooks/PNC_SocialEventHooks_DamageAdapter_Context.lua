-- Server-authoritative combat damage observations for social relationships.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local Network = PNC.Network
local Factions = PNC.Factions

local POLL_INTERVAL_MS = 100
local VANILLA_MARKER_WINDOW_MS = 500
local WITNESS_RADIUS = tonumber(H.WitnessRadius) or 12
local PLAYER_DELIVERY_RADIUS = math.max(WITNESS_RADIUS * 2, 24)

Hooks.CombatEventSequence = Hooks.CombatEventSequence or 0
Hooks.VanillaDamageSnapshots = Hooks.VanillaDamageSnapshots or {}
Hooks.VanillaDamageMarkers = Hooks.VanillaDamageMarkers or {}
Hooks.LastVanillaDamagePollAt = Hooks.LastVanillaDamagePollAt or 0
Hooks.LastTeammateHurtAt = Hooks.LastTeammateHurtAt or {}
Hooks.LastPlayerHurtWitnessAt = Hooks.LastPlayerHurtWitnessAt or {}
Hooks.PlayerHurtWitnessThrottleOrder =
    Hooks.PlayerHurtWitnessThrottleOrder or {}
Hooks.PlayerHurtWitnessCooldownMs =
    tonumber(Hooks.PlayerHurtWitnessCooldownMs) or 750

local function call(object, method, ...)
    if not object or not object[method] then
        return nil
    end
    local ok, value = pcall(object[method], object, ...)
    if ok then
        return value
    end
    return nil
end

local function audit(fields)
    if not (PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.DebugCombatCallbacks == true)
    then
        return
    end
    local message = "[RelationshipCombatAudit] " .. table.concat(fields, " ")
    if Core and Core.LogInfo then
        Core.LogInfo(message)
    elseif print then
        print("[PNC][INFO] " .. message)
    end
end

local function nowMillis()
    if Core and Core.Now then
        return tonumber(Core.Now()) or 0
    end
    return 0
end

local function worldAgeHours()
    if H and H.WorldAgeHours then
        return tonumber(H.WorldAgeHours()) or 0
    end
    return 0
end

local function isAuthority()
    if Core and Core.IsAuthority then
        return Core.IsAuthority() == true
    end
    return true
end

local function nextEventID(eventType, actorKey, subjectID)
    Hooks.CombatEventSequence = Hooks.CombatEventSequence + 1
    return "social:" .. tostring(eventType) .. ":"
        .. tostring(actorKey) .. ":" .. tostring(subjectID) .. ":"
        .. tostring(worldAgeHours()) .. ":"
        .. tostring(Hooks.CombatEventSequence)
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

local function positionOf(object)
    return {
        x = call(object, "getX"),
        y = call(object, "getY"),
        z = call(object, "getZ"),
    }
end

local function emitRelationshipEvent(
    player,
    npcID,
    eventType,
    eventID,
    context,
    position
)
    local targetKey
    local event
    local ok
    local processed
    local reason
    local detail
    local sent
    local presentationReason
    local callOK
    if not player or not npcID then
        return false, "missing_presentation_target"
    end
    targetKey = EntityRef and EntityRef.ForNPC
        and EntityRef.ForNPC(npcID) or nil
    if not targetKey then
        return false, "npc_key_unavailable"
    end
    if not PNC.SocialEvents
        or type(PNC.SocialEvents.Emit) ~= "function"
    then
        return false, "social_event_service_unavailable"
    end
    event = {
        id = eventID,
        type = eventType,
        actorKey = Hooks.ResolvePlayerKey(player),
        targetKey = targetKey,
        occurredAt = worldAgeHours(),
        sourceSystem = "combat",
        x = position and position.x or nil,
        y = position and position.y or nil,
        z = position and position.z or nil,
        context = context or {},
    }
    if not event.actorKey then
        return false, "player_identity_unavailable"
    end
    callOK, processed = pcall(PNC.SocialEvents.Emit, event)
    if not callOK then
        audit({
            "luaSide=server",
            "event=" .. tostring(eventType),
            "phase=relationship_dispatch",
            "result=false",
            "reason=emit_error",
            "eventID=" .. tostring(eventID),
            "npcID=" .. tostring(npcID),
        })
        return false, "emit_error"
    end
    reason = processed and processed.reason or "unknown_result"
    if not processed or processed.ok ~= true then
        audit({
            "luaSide=server",
            "event=" .. tostring(eventType),
            "phase=relationship_dispatch",
            "result=false",
            "reason=" .. tostring(reason),
            "eventID=" .. tostring(eventID),
            "npcID=" .. tostring(npcID),
        })
        return false, reason
    end
    detail = processed.details and processed.details[1] or nil
    if Network
        and type(Network.SendConversationRelationshipForNPC) == "function"
    then
        callOK, sent, presentationReason = pcall(
            Network.SendConversationRelationshipForNPC,
            player,
            npcID,
            eventType,
            {
                source = eventType,
                eventID = processed.eventID or eventID,
                relationshipBefore = detail
                    and detail.relationshipBefore or nil,
                relationshipAfter = detail
                    and detail.relationshipAfter or nil,
                relationshipDelta = relationshipDelta(
                    detail and detail.relationshipBefore or nil,
                    detail and detail.relationshipAfter or nil
                ),
                npcID = tostring(npcID),
            }
        )
        if not callOK then
            sent = false
            presentationReason = "transport_error"
        end
    else
        sent = false
        presentationReason = "relationship_transport_unavailable"
    end
    audit({
        "luaSide=server",
        "event=" .. tostring(eventType),
        "phase=relationship_feedback",
        "result=" .. tostring(sent == true),
        "reason=" .. tostring(presentationReason or "nil"),
        "eventID=" .. tostring(eventID),
        "npcID=" .. tostring(npcID),
        "approvalDelta=" .. tostring(
            relationshipDelta(
                detail and detail.relationshipBefore or nil,
                detail and detail.relationshipAfter or nil
            ).approval
        ),
        "respectDelta=" .. tostring(
            relationshipDelta(
                detail and detail.relationshipBefore or nil,
                detail and detail.relationshipAfter or nil
            ).respect
        ),
    })
    audit({
        "luaSide=server",
        "event=" .. tostring(eventType),
        "phase=relationship_dispatch",
        "result=true",
        "reason=applied",
        "eventID=" .. tostring(eventID),
        "npcID=" .. tostring(npcID),
    })
    return true, sent == true and "presented" or "applied_without_presentation"
end

local function emitForWitness(
    player,
    npcID,
    eventType,
    eventID,
    context,
    position
)
    local actorKey = Hooks.ResolvePlayerKey(player)
    local eventContext = type(context) == "table" and context or {}
    if not actorKey then
        return false, "player_identity_unavailable"
    end
    return emitRelationshipEvent(
        player,
        npcID,
        eventType,
        eventID,
        eventContext,
        position
    )
end

local function sameID(left, right)
    return left ~= nil and right ~= nil
        and tostring(left) == tostring(right)
end

local function factionIDForRecord(record)
    if Factions and Factions.GetFactionID then
        return Factions.GetFactionID(record)
    end
    return record and record.affiliation
        and record.affiliation.factionID or nil
end

local function playerFactionIDFor(player, actorKey)
    local faction
    if Factions and Factions.GetPlayerDiplomacyFaction then
        faction = Factions.GetPlayerDiplomacyFaction(player)
    end
    if not faction and actorKey
        and Factions
        and Factions.GetDiplomacyFactionForPlayerKey
    then
        faction = Factions.GetDiplomacyFactionForPlayerKey(actorKey)
    end
    return faction and faction.id or nil
end

local function factionIDForMember(member)
    return member and member.affiliation
        and member.affiliation.factionID or nil
end

local function socialRole(record)
    local interactions = PNC.VanillaEmoteInteractions
    if interactions and type(interactions.ResolveNPCType) == "function" then
        local ok, value = pcall(interactions.ResolveNPCType, record)
        if ok and value then return tostring(value) end
    end
    if record and record.recruited == true then return "colonist" end
    if record and record.tacticalClass == "hostile" then return "hostile" end
    return "neutral"
end

local function distanceSqBetween(left, right)
    local leftPosition = positionOf(left)
    local rightPosition = positionOf(right)
    if not leftPosition.x or not leftPosition.y
        or not rightPosition.x or not rightPosition.y
    then
        return nil
    end
    return Core and Core.DistanceSq
        and Core.DistanceSq(
            leftPosition.x,
            leftPosition.y,
            rightPosition.x,
            rightPosition.y
        )
        or ((leftPosition.x - rightPosition.x) ^ 2
            + (leftPosition.y - rightPosition.y) ^ 2)
end

local function playerCanReceive(player, targetBody, targetRecord)
    local target = targetBody or targetRecord
    local distance = distanceSqBetween(player, target)
    if not distance then return false end
    return distance <= PLAYER_DELIVERY_RADIUS * PLAYER_DELIVERY_RADIUS
end

local function witnessCanSeeDamage(observer, observerBody, targetBody, attacker)
    if not H.LiveNPCIsWitness then return false end
    local ok, result = pcall(
        H.LiveNPCIsWitness,
        observer,
        observerBody,
        targetBody,
        attacker,
        WITNESS_RADIUS * WITNESS_RADIUS
    )
    return ok and result == true
end

local function damageAttackerID(attacker, hit)
    return tostring(
        hit and (hit.attackerID or hit.attackerZombieID)
            or call(attacker, "getOnlineID")
            or "unknown"
    )
end

H.DamageCall = call
H.DamageAudit = audit
H.DamageNowMillis = nowMillis
H.DamageWorldAgeHours = worldAgeHours
H.DamageIsAuthority = isAuthority
H.DamageNextEventID = nextEventID
H.DamageRelationshipDelta = relationshipDelta
H.DamagePositionOf = positionOf
H.DamageEmitRelationshipEvent = emitRelationshipEvent
H.DamageEmitForWitness = emitForWitness
H.DamageSameID = sameID
H.DamageFactionIDForRecord = factionIDForRecord
H.DamagePlayerFactionIDFor = playerFactionIDFor
H.DamageFactionIDForMember = factionIDForMember
H.DamageSocialRole = socialRole
H.DamageDistanceSqBetween = distanceSqBetween
H.DamagePlayerCanReceive = playerCanReceive
H.DamageWitnessCanSeeDamage = witnessCanSeeDamage
H.DamageAttackerID = damageAttackerID
